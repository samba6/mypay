import * as Yup from "yup";
import { ValidationError } from "yup";

import CREATE_META_GQL from "../../graphql/create-meta.mutation";
import { toRunnableDocument } from "../../graphql/helpers";
import { stringifyGraphQlErrors } from "../../graphql/helpers";
import { CreateMeta_meta } from "../../graphql/gen.types";
import { makeFormThings } from "../../utils/form-things";
import { setFieldError } from "../../utils/form-things";
import { clearFieldErrors } from "../../utils/form-things";
import { setMainErrorClass } from "../../utils/form-things";
import { formHasErrors } from "../../utils/form-things";
import { getFieldAndErrorEls } from "../../utils/form-things";
import { AppSocket } from "../../socket";
import { META_TYPENAME } from "../../constants";
import { OFFLINE_MSG } from "../../constants";
import { Database } from "../../database";
import { prepForOfflineSave } from "../../database";

enum FormElementsName {
  BREAK_TIME_SECS = "breakTimeSecs",
  PAY_PER_HOUR = "payPerHr",
  NIGHT_SUPPL_PAY = "nightSupplPayPct",
  SUNDAY_SUPPL_PAY = "sundaySupplPayPct"
}

interface NewMetaFormData {
  // tslint:disable-next-line:no-any
  [key: string]: any;
}

interface Props {
  socket: AppSocket;
  onMetaCreated: (data: CreateMeta_meta) => void;
  database: Database;
}

const genericError = "Invalid Number";

export class NewMeta {
  schema = Yup.object().shape({
    [FormElementsName.BREAK_TIME_SECS]: Yup.number()
      .typeError(genericError)
      .required()
      .positive()
      .integer(),

    [FormElementsName.PAY_PER_HOUR]: Yup.number()
      .typeError(genericError)
      .required()
      .positive(),

    [FormElementsName.NIGHT_SUPPL_PAY]: Yup.number()
      .typeError(genericError)
      .required()
      .positive(),

    [FormElementsName.SUNDAY_SUPPL_PAY]: Yup.number()
      .typeError(genericError)
      .required()
      .positive()
  });

  formSubmit: HTMLButtonElement;

  formReset: HTMLButtonElement;

  mainErrorContainer: HTMLDivElement;

  formThings = makeFormThings();

  inputs: NodeListOf<HTMLInputElement>;

  constructor(private props: Props) {}

  setUpDOM = () => {
    this.formSubmit = document.getElementById(
      "new-meta-form-submit"
    ) as HTMLButtonElement;

    this.formReset = document.getElementById(
      "new-meta-form-reset"
    ) as HTMLButtonElement;

    this.mainErrorContainer = document.getElementById(
      "new-meta-form__error-main"
    ) as HTMLDivElement;

    this.formThings = makeFormThings();

    this.inputs = document.querySelectorAll(".new-meta-form__control");

    Array.prototype.forEach.call(this.inputs, this.setUpInput);

    if (this.formSubmit && this.formReset && this.mainErrorContainer) {
      this.formSubmit.addEventListener("click", this.submitElHandler);
      this.formReset.addEventListener("click", this.resetElHandler);
    }
  };

  setUpInput = (el: HTMLInputElement) => {
    const name = el.name;
    const { fieldEl, errorEl } = getFieldAndErrorEls(el);

    const focusListener = () => {
      clearFieldErrors({ fieldEl, errorEl });
      setMainErrorClass(this.mainErrorContainer, "hide");

      if (!formHasErrors(this.formThings.errors)) {
        this.formSubmit.disabled = false;
      }
    };

    const inputListener = (evt: InputEvent) => {
      const target = evt.target as HTMLInputElement;
      setMainErrorClass(this.mainErrorContainer, "hide");

      if (!target) {
        return;
      }

      Yup.reach(this.schema, target.name)
        .validate(target.value)
        .then(() => {
          clearFieldErrors({ fieldEl, errorEl });

          this.formThings.errors = {
            ...this.formThings.errors,
            [name]: undefined
          };

          if (!formHasErrors(this.formThings.errors)) {
            this.formSubmit.disabled = false;
          }
        })
        .catch(error => {
          setFieldError({ fieldEl, errorEl }, error.message);
          this.formSubmit.disabled = true;

          this.formThings.errors = {
            ...this.formThings.errors,
            [name]: error
          };
        });
    };

    this.formThings.doms[name] = {
      el,
      fieldEl,
      errorEl,
      focusListener,
      inputListener
    };

    el.addEventListener("focus", focusListener);
    el.addEventListener("input", inputListener);
    el.addEventListener("blur", inputListener);
  };

  submitElHandler = () => {
    const data = {} as NewMetaFormData;

    Object.keys(this.formThings.doms).forEach(
      k => (data[k] = this.formThings.doms[k].el.value)
    );

    this.schema
      .validate(data, { abortEarly: false })
      .then((meta: { [k: string]: number }) => {
        // The user input is in minutes, so we convert break_time_secs to
        // seconds by multiplying minutes by 60
        meta = { ...meta, breakTimeSecs: meta.breakTimeSecs * 60 };

        if (window.appInterface.socketConnected) {
          this.saveOnline(meta);
        } else {
          this.saveOffline(meta);
        }

        this.formSubmit.classList.add("loading");
        this.formSubmit.disabled = true;
        this.formReset.disabled = true;
        this.formThings.errors = {};
      })
      .catch(errors => {
        this.formSubmit.disabled = true;
        errors.inner.map((err: ValidationError) => {
          setFieldError(this.formThings.doms[err.path], err.message);

          this.formThings.errors = {
            ...this.formThings.errors,
            [err.path]: err
          };
        });
      });
  };

  // tslint:disable-next-line:no-any
  saveOnline = (meta: any) => {
    this.props.socket.queryGraphQl({
      params: toRunnableDocument(CREATE_META_GQL, {
        meta
      }),

      ok: ({ meta: createdMeta }) => {
        this.props.database.db.put(createdMeta);
        this.props.onMetaCreated(createdMeta);
      },

      error: reason => {
        this.formSubmit.classList.remove("loading");
        this.mainErrorContainer.textContent = stringifyGraphQlErrors(
          "meta",
          reason
        );

        setMainErrorClass(this.mainErrorContainer, "show");
        this.formReset.disabled = false;
      },

      onTimeout: () => this.saveOffline(meta)
    });
  };

  // tslint:disable-next-line:no-any
  saveOffline = async (meta: any) => {
    this.mainErrorContainer.textContent = OFFLINE_MSG;
    setMainErrorClass(this.mainErrorContainer, "show");

    const offlineData = prepForOfflineSave(META_TYPENAME);
    const offlineMeta = {
      ...meta,
      ...offlineData
    };

    await this.props.database.db.put(offlineMeta);

    setTimeout(() => {
      this.props.onMetaCreated(offlineMeta);
    }, 1000);
  };

  resetElHandler = () => {
    Object.keys(this.formThings.doms).forEach(k => {
      const { el, fieldEl, errorEl } = this.formThings.doms[k];
      el.value = "";

      if (!(fieldEl && errorEl)) {
        return;
      }

      clearFieldErrors({ fieldEl, errorEl });
      setMainErrorClass(this.mainErrorContainer, "hide");
    });

    this.formSubmit.classList.remove("loading");
    this.formSubmit.disabled = false;
    this.formThings.errors = {};
  };

  cleanUp = () => {
    this.formSubmit.removeEventListener("click", this.submitElHandler);
    this.formReset.removeEventListener("click", this.resetElHandler);

    Object.values(this.formThings.doms).forEach(v => {
      const { el, focusListener, inputListener } = v;
      el.removeEventListener("focus", focusListener);
      el.removeEventListener("input", inputListener);
      el.removeEventListener("blur", inputListener);
    });
  };
}

export default NewMeta;
