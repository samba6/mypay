defmodule BurdaWeb.Schema.ShiftTest do
  use Burda.DataCase

  alias BurdaWeb.Schema
  alias BurdaWeb.Query.Shift, as: Query
  alias Burda.Factory.Shift, as: Factory
  alias Burda.Factory.Meta, as: MetaFactory
  alias Burda.Shift.Api

  @iso_time "{ISOtime}"
  @iso_date "{ISOdate}"
  @date_time_pattern ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z/

  describe "query" do
    test "Get all shifts no filter" do
      meta = MetaFactory.insert()
      shift = Factory.insert(%{}, meta)

      id = Integer.to_string(shift.id)
      date = format_date(shift.date)
      start_time = format_time(shift.start_time)
      end_time = format_time(shift.end_time)
      hours_gross = shift.hours_gross
      normal_hours = shift.normal_hours
      night_hours = shift.night_hours
      sunday_hours = shift.sunday_hours
      normal_pay = Decimal.to_string(shift.normal_pay)
      night_suppl_pay = Decimal.to_string(shift.night_suppl_pay)
      sunday_suppl_pay = Decimal.to_string(shift.sunday_suppl_pay)
      total_pay = Decimal.to_string(shift.total_pay)

      meta_id = Integer.to_string(meta.id)

      assert {:ok,
              %{
                data: %{
                  "shifts" => [
                    %{
                      "id" => ^id,
                      "_id" => id_,
                      "date" => ^date,
                      "startTime" => ^start_time,
                      "endTime" => ^end_time,
                      "hoursGross" => ^hours_gross,
                      "normalHours" => ^normal_hours,
                      "nightHours" => ^night_hours,
                      "sundayHours" => ^sunday_hours,
                      "normalPay" => ^normal_pay,
                      "nightSupplPay" => ^night_suppl_pay,
                      "sundaySupplPay" => ^sunday_suppl_pay,
                      "totalPay" => ^total_pay,
                      "meta" => %{
                        "id" => ^meta_id
                      }
                    }
                  ]
                }
              }} = Absinthe.run(Query.query_all(), Schema)

      assert Regex.match?(@date_time_pattern, id_)
    end

    test "Get all shifts filtered by year and month ordered by date desc" do
      shift1 = Factory.insert(date: ~D[2014-05-15])
      shift2 = Factory.insert(date: ~D[2014-05-05])
      shift3 = Factory.insert(date: ~D[2014-05-25])
      _shift = Factory.insert(date: ~D[2013-05-15])

      shift1_id = Integer.to_string(shift1.id)
      shift2_id = Integer.to_string(shift2.id)
      shift3_id = Integer.to_string(shift3.id)

      assert {:ok,
              %{
                data: %{
                  "shifts" => [
                    %{
                      "id" => ^shift3_id
                    },
                    %{
                      "id" => ^shift1_id
                    },
                    %{
                      "id" => ^shift2_id
                    }
                  ]
                }
              }} =
               Absinthe.run(
                 Query.query_all(),
                 Schema,
                 variables: %{
                   "shift" => %{
                     "where" => %{
                       "month" => 5,
                       "year" => 2014
                     },
                     "orderBy" => %{
                       "date" => "DESC"
                     }
                   }
                 }
               )
    end
  end

  describe "mutation" do
    test "create shift succeeds" do
      meta = MetaFactory.insert()

      params =
        Factory.params()
        |> Map.put("metaId", Integer.to_string(meta.id))
        |> Enum.map(fn
          {:date, d} -> {"date", format_date(d)}
          {:end_time, t} -> {"endTime", format_time(t)}
          {:start_time, t} -> {"startTime", format_time(t)}
          x -> x
        end)
        |> Enum.into(%{})

      assert {:ok,
              %{
                data: %{
                  "shift" => %{
                    "id" => _id,
                    "date" => _,
                    "startTime" => _,
                    "endTime" => _,
                    "hoursGross" => _,
                    "normalHours" => _,
                    "nightHours" => _,
                    "sundayHours" => _,
                    "normalPay" => _,
                    "nightSupplPay" => _,
                    "sundaySupplPay" => _,
                    "totalPay" => _
                  }
                }
              }} =
               Absinthe.run(
                 Query.create_shift(),
                 Schema,
                 variables: %{
                   "shift" => params
                 }
               )
    end

    test "create shift fails when wrong meta supplied" do
      params =
        Factory.params()
        |> Map.put("metaId", "0")
        |> Enum.map(fn
          {:date, d} -> {"date", format_date(d)}
          {:end_time, t} -> {"endTime", format_time(t)}
          {:start_time, t} -> {"startTime", format_time(t)}
          x -> x
        end)
        |> Enum.into(%{})

      msg =
        Poison.encode!(%{
          meta_id: Api.meta_id_not_found_error("0")
        })

      assert {:ok,
              %{
                errors: [
                  %{
                    message: ^msg
                  }
                ]
              }} =
               Absinthe.run(
                 Query.create_shift(),
                 Schema,
                 variables: %{
                   "shift" => params
                 }
               )
    end
  end

  defp format_time(%Time{} = time), do: Timex.format!(time, @iso_time)
  defp format_date(%Date{} = date), do: Timex.format!(date, @iso_date)
end
