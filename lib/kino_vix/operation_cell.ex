defmodule KinoVix.OperationCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/operation_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Vix Operation"

  alias Vix.Vips.OperationHelper, as: Ops

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "variable" => Kino.SmartCell.prefixed_var_name("image", attrs["variable"]),
      "operation_name" => attrs["operation_name"] || "",
      "required_input" => attrs["required_input"] || [],
      "optional_input" => attrs["optional_input"] || [],
      "required_output" => attrs["required_output"] || [],
      "optional_output" => attrs["optional_output"] || []
    }

    vix_operations = vix_operations()

    select_op_list =
      Map.keys(vix_operations)
      |> Enum.sort()
      |> Enum.map(fn name ->
        %{"label" => name, "value" => name}
      end)

    ctx =
      assign(ctx,
        fields: fields,
        operations: vix_operations,
        select_op_list: select_op_list,
        enums: vix_enums(),
        flags: vix_flags()
      )

    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      operations: ctx.assigns.operations,
      select_op_list: ctx.assigns.select_op_list,
      enums: ctx.assigns.enums,
      flags: ctx.assigns.flags
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    updated_fields = to_updates(ctx.assigns, field, value)
    ctx = update(ctx, :fields, &Map.merge(&1, updated_fields))

    broadcast_event(ctx, "update", %{"fields" => updated_fields})
    {:noreply, ctx}
  end

  defp to_updates(%{fields: fields}, "variable", value) do
    if Kino.SmartCell.valid_variable_name?(value) do
      %{"variable" => value}
    else
      %{"variable" => fields["variable"]}
    end
  end

  defp to_updates(%{operations: operations, enums: enums, flags: _flags}, "operation_name", name) do
    %{
      required_input: required_input,
      optional_input: optional_input,
      required_output: required_output,
      optional_output: optional_output
    } = Map.fetch!(operations, name)

    %{
      "operation_name" => name,
      "required_input" => prepare_spec(required_input, enums),
      "optional_input" => prepare_spec(optional_input, enums),
      "required_output" => prepare_spec(required_output),
      "optional_output" => prepare_spec(optional_output)
    }

    # |> IO.inspect(label: "to_updates")
  end

  defp to_updates(%{fields: fields}, field, value) do
    required_input = update_input_param(fields["required_input"], field, value)
    optional_input = update_input_param(fields["optional_input"], field, value)

    %{"required_input" => required_input, "optional_input" => optional_input}
  end

  defp prepare_spec(specs, enums \\ %{}) do
    specs
    |> Jason.encode!()
    |> Jason.decode!()
    |> Enum.map(&Map.put(&1, "value", ""))
    |> Enum.map(fn
      %{"spec_type" => "GParamEnum", "value_type" => value_type} = spec ->
        options = Enum.map(enums[value_type], fn v -> %{"label" => v, "value" => v} end)
        Map.put(spec, "enum_options", options)

      spec ->
        spec
    end)
  end

  @impl true
  def to_attrs(%{assigns: %{fields: fields}}) do
    Map.take(
      fields,
      ~w|variable operation_name required_input optional_input required_output optional_output|
    )
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> to_quoted()
    |> Kino.SmartCell.quoted_to_string()
  end

  defp to_quoted(%{"operation_name" => name} = attrs) do
    required_input =
      attrs["required_input"]
      |> Enum.map(fn spec -> cast_value(spec) end)

    optional_input =
      attrs["optional_input"]
      |> Enum.filter(fn spec -> spec["value"] != "" end)
      |> Enum.map(fn spec -> {String.to_atom(spec["param_name"]), cast_value(spec)} end)

    input =
      if optional_input != [] do
        required_input ++ [optional_input]
      else
        required_input
      end

    func_name = String.to_atom(name <> "!")

    cond do
      length(attrs["required_output"]) == 0 ->
        quote do
          :ok = Vix.Vips.Operation.unquote(func_name)(unquote_splicing(input))
        end

      Enum.any?(required_input, &(&1 == nil)) ->
        quote do
          # Input data is incomplete
        end

      length(attrs["required_output"]) == 1 &&
          length(attrs["optional_output"]) == 0 ->
        quote do
          unquote(quoted_var(attrs["variable"])) =
            Vix.Vips.Operation.unquote(func_name)(unquote_splicing(input))
        end

      length(attrs["required_output"]) == 1 &&
          length(attrs["optional_output"]) > 0 ->
        quote do
          {unquote(quoted_var(attrs["variable"])), _flags} =
            Vix.Vips.Operation.unquote(func_name)(unquote_splicing(input))

          unquote(quoted_var(attrs["variable"]))
        end

      true ->
        quote do
          unquote(quoted_var(attrs["variable"])) =
            Vix.Vips.Operation.unquote(func_name)(unquote_splicing(input))
        end
    end
  end

  defp cast_value(spec) do
    case spec do
      %{"value" => ""} ->
        nil

      %{"value_type" => "gchararray", "value" => value} ->
        value

      %{"spec_type" => "GParamInt", "value" => value} ->
        String.to_integer(value)

      %{"spec_type" => "GParamDouble", "value" => value} ->
        {value, ""} = Float.parse(value)
        value

      %{"spec_type" => "GParamEnum", "value" => value} ->
        String.to_atom(value)

      %{"spec_type" => "GParamBoolean", "value" => value} ->
        case value do
          "true" -> true
          "false" -> false
        end

      %{"value_type" => "VipsBlob", "value" => value} ->
        value

      %{"value_type" => "VipsArrayInt", "value" => value} ->
        String.split(value, " ", trim: true)
        |> Enum.map(fn v ->
          case Integer.parse(v) do
            {v, ""} -> v
            _ -> raise "Value must be string of integers separated by space"
          end
        end)

      %{"value_type" => "VipsArrayDouble", "value" => value} ->
        String.split(value, " ", trim: true)
        |> Enum.map(fn v ->
          case Float.parse(v) do
            {v, ""} -> v
            _ -> raise "Value must be string of floats separated by space"
          end
        end)

      %{"value_type" => "VipsImage", "value" => value} ->
        quoted_var(value)
    end
  end

  defp quoted_var(string), do: {String.to_atom(string), [], nil}

  defp update_input_param(params, field, value) do
    Enum.map(params, fn
      %{"param_name" => ^field} = spec -> Map.put(spec, "value", value)
      spec -> spec
    end)
  end

  defp vix_operations do
    Ops.vips_immutable_operation_list()
    |> Map.new(fn operation_name ->
      spec = Ops.operation_args_spec(operation_name)

      spec = %{
        desc: spec.desc,
        required_input: normalize_spec(spec.in_req_spec),
        optional_input: normalize_spec(spec.in_opt_spec),
        required_output: normalize_spec(spec.out_req_spec),
        optional_output: normalize_spec(spec.out_opt_spec)
      }

      {operation_name, spec}
    end)
  end

  defp vix_enums do
    Ops.vips_enum_list()
    |> Map.new(fn {enum_name, enums} ->
      {list, _} = Enum.unzip(enums)
      {enum_name, Enum.map(list, &to_string/1)}
    end)
  end

  defp vix_flags do
    Ops.vips_flag_list()
    |> Map.new(fn {flag_name, flags} ->
      {list, _} = Enum.unzip(flags)
      {flag_name, Enum.map(list, &to_string/1)}
    end)
  end

  defp normalize_spec(param_spec) do
    param_spec
    |> Enum.map(&Map.from_struct(&1))
    |> Enum.map(fn
      %{data: {min, max, default}} = spec ->
        Map.merge(spec, %{min: min, max: max, default: default})

      %{data: nil} = spec ->
        spec

      %{data: default} = spec ->
        Map.merge(spec, %{default: default})
    end)
    |> Enum.map(&Map.drop(&1, [:data, :type]))
  end
end
