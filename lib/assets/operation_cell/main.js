import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, info) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");

  const BaseSelect = {
    name: "BaseSelect",

    props: {
      label: {
        type: String,
        default: ''
      },
      selectClass: {
        type: String,
        default: 'input'
      },
      modelValue: {
        type: String,
        default: ''
      },
      options: {
        type: Array,
        default: [],
        required: true
      },
      required: {
        type: Boolean,
        default: false
      },
      inline: {
        type: Boolean,
        default: false
      },
      grow: {
        type: Boolean,
        default: false
      },
    },

    methods: {
      available(value, options) {
        return value ? options.map((option) => option.value).includes(value) : true;
      }
    },

    template: `
    <div v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']">
      <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
        {{ label }}
      </label>
      <select
        :value="modelValue"
        v-bind="$attrs"
        @change="$emit('update:data', $event.target.value)"
        v-bind:class="[selectClass, { unavailable: !available(modelValue, options) }]"
      >
        <option
          v-for="option in options"
          :value="option.value"
          :key="option"
          :selected="option.value === modelValue"
        >{{ option.label }}</option>
        <option
          v-if="!available(modelValue, options)"
          class="unavailable"
          :value="modelValue"
        >{{ modelValue }}</option>
      </select>
    </div>
    `
  };

  const BaseInput = {
    name: "BaseInput",

    props: {
      label: {
        type: String,
        default: ''
      },
      inputClass: {
        type: String,
        default: 'input'
      },
      modelValue: {
        type: [String, Number],
        default: ''
      },
      inline: {
        type: Boolean,
        default: false
      },
      grow: {
        type: Boolean,
        default: false
      },
      number: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      emptyClass() {
        if (this.modelValue === "") {
          return "empty";
        }
      }
    },

    template: `
    <div v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']">
      <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
        {{ label }}
      </label>
      <input
        :value="modelValue"
        @input="$emit('update:data', $event.target.value)"
        v-bind="$attrs"
        v-bind:class="[inputClass, number ? 'input-number' : '', emptyClass]"
      >
    </div>
    `
  };

  const RangeInput = {
    name: "RangeInput",

    props: {
      label: {
        type: String,
        default: ''
      },
      inputClass: {
        type: String,
        default: 'input'
      },
      modelValue: {
        type: [String, Number],
        default: ''
      },
      inline: {
        type: Boolean,
        default: false
      },
      grow: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      emptyClass() {
        if (this.modelValue === "") {
          return "empty";
        }
      }
    },

    template: `
    <div v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']">
      <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
        {{ label }}
      </label>
      <input
        type="range"
        :value="modelValue"
        @input="$emit('update:data', $event.target.value)"
        v-bind="$attrs"
        v-bind:min="min"
        v-bind:max="max"
        v-bind:step="0.01"
        class="inputClass input-range"
      >
    </div>
    `
  };

  const OperationInput = {
    name: "OperationInput",

    components: {
      BaseInput: BaseInput,
      BaseSelect: BaseSelect,
      RangeInput: RangeInput,
    },

    props: {
      input: {
        type: Object,
        default: {}
      },
      required: {
        type: Boolean,
        default: false
      },
    },

    methods: {
      isNumberField(spec_type) {
        return spec_type == "GParamDouble" ||
          spec_type == "GParamInt";
      },

      isCheckboxField(spec_type) {
        return spec_type == "GParamBoolean"
      },

      isDropdownField(spec_type) {
        return spec_type == "GParamEnum";
      },

      isTextField(spec_type) {
        return spec_type != "GParamDouble" &&
          spec_type != "GParamInt" &&
          spec_type != "GParamBoolean" &&
          spec_type != "GParamEnum";
      },
    },

    template: `
      <BaseInput
        type="text"
        v-if="isTextField(input.spec_type)"
        v-bind:name="input.param_name"
        v-bind:label="input.desc"
        v-bind:placeholder="input.param_name"
        v-model="input.value"
        v-bind:required="required"
        inputClass="input"
        :grow
      />

      <BaseInput
        type="number"
        v-if="isNumberField(input.spec_type)"
        v-bind:name="input.param_name"
        v-bind:label="input.desc"
        v-bind:placeholder="input.param_name"
        v-model="input.value"
        v-bind:required="required"
        inputClass="input"
        :number
        :grow
      />

      <BaseSelect
        v-if="isCheckboxField(input.spec_type)"
        v-bind:name="input.param_name"
        v-bind:label="input.desc"
        v-bind:placeholder="input.param_name"
        v-model="input.value"
        selectClass="input"
        v-bind:options="[{'label': '', 'value': ''}, {'label': 'true', 'value': 'true'}, {'label': 'false', 'value': 'false'}]"
        v-bind:required="required"
        :grow
      />

      <BaseSelect
        v-if="isDropdownField(input.spec_type)"
        v-bind:name="input.param_name"
        v-bind:label="input.desc"
        v-bind:placeholder="input.param_name"
        v-model="input.value"
        selectClass="input"
        v-bind:options="input.enum_options"
        v-bind:required="required"
        :grow
      />
    `
  };

  const OperationForm = {
    name: "OperationForm",

    components: {
      OperationInput: OperationInput
    },

    data() {
      return {
        showOptionalParams: false,
      };
    },

    props: {
      fields: {
        type: Object,
        default: {}
      },
      enums: {
        type: Object,
        default: {}
      },
      operation: {
        type: Object,
        default: {}
      }
    },

    methods: {
      toggleOptionalParams(_) {
        this.showOptionalParams = !this.showOptionalParams;
      },
    },


    template: `
    <div>
      <div>
        <label v-bind:class="[inline ? 'inline-input-label' : 'input-label', 'operation-note']">
          {{ operation.desc }}
        </label>
      </div>

      <div class="operation-parameter">
        <div class="operation-parameter" v-for="input in fields.required_input">
          <OperationInput v-bind:input="input" v-bind:required="true" />
        </div>
      </div>

      <label v-if="fields.optional_input.length" v-bind:class="[inline ? 'inline-input-label' : 'input-label', 'operation-note']" @click="toggleOptionalParams" >
        Optional Parameters
      </label>

       <div v-bind:class="['operation-parameter', this.showOptionalParams ? '' : 'hidden' ]">
         <div class="operation-parameter" v-for="input in fields.optional_input">
          <OperationInput v-bind:input="input" v-bind:required="false" />
         </div>
       </div>
    </div>`
  };

  const app = Vue.createApp({
    components: {
      BaseInput: BaseInput,
      BaseSelect: BaseSelect,
      OperationForm: OperationForm,
      OperationInput: OperationInput,
    },

    template: `
    <div class="app">
      <!-- Info Messages -->
      <form @change="handleFieldChange">
        <div class="container">

          <div class="row header">
            <BaseSelect
              name="operation_name"
              label=" Operation "
              v-model="fields.operation_name"
              selectClass="input input--xs"
              :inline
              :options="availableOperations"
            />

            <BaseInput
              name="variable"
              label=" Assign to "
              type="text"
              v-model="fields.variable"
              inputClass="input input--xs input-text"
              :inline
              v-if="fields.required_output.length"
            />
          </div>

          <OperationForm
            v-bind:fields="fields"
            v-bind:operation="operations[fields.operation_name]"
            v-bind:enums="enums"
          />

        </div>
      </form>
    </div>
    `,

    data() {
      return {
        fields: info.fields,
        operations: info.operations,
        availableOperations: info.select_op_list,
        enums: info.enums,
      }
    },

    computed: { },

    methods: {
      handleFieldChange(event) {
        const { name, value } = event.target;

        if (name) {
          ctx.pushEvent("update_field", {field: name, value});
        }
      },
    }
  }).mount(ctx.root);

  ctx.handleEvent("update", ({ fields }) => {
    setValues(fields);
  });

  ctx.handleSync(() => {
    // Synchronously invokes change listeners
    document.activeElement &&
      document.activeElement.dispatchEvent(new Event("change", { bubbles: true }));
  });

  function setValues(fields) {
    for (const field in fields) {
      app.fields[field] = fields[field];
    }
  }
}
