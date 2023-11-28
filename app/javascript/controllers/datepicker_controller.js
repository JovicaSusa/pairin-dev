import { Controller } from "@hotwired/stimulus"
import AirDatepicker from 'air-datepicker'
import localeEn from 'air-datepicker/locale/en';
import flatpickr from "flatpickr"

export default class extends Controller {
  connect() {
    console.log('ajmo');

    flatpickr("#blah", {})
  }
}
