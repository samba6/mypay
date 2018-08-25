import { Subject } from "rxjs";
import { NextObserver } from "rxjs";
import { Subscription } from "rxjs";

export enum Topic {
  SHIFT_SYNCED_SUCCESS = "emitter__event-shift-synced-success"
}

// tslint:disable-next-line:no-any
type TPayload = any;

export class Emitter {
  subs$: Map<Topic, Subject<TPayload>> = new Map();
  unSub$ = new Subscription();

  emit = (topic: Topic, payload: TPayload) => {
    let sub$ = this.subs$.get(topic);

    if (!sub$) {
      sub$ = new Subject();
      this.subs$.set(topic, sub$);
    }

    sub$.next(payload);
  };

  listen = (topic: Topic, cb: NextObserver<TPayload>) => {
    let sub$ = this.subs$.get(topic);

    if (!sub$) {
      sub$ = new Subject();
      this.subs$.set(topic, sub$);
    }

    return this.unSub$.add(sub$.subscribe(cb));
  };

  dispose = () => {
    this.unSub$.unsubscribe();
    this.subs$ = new Map();
  };
}

export default Emitter;
