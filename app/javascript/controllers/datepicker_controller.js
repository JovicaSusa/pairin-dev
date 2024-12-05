import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  connect() {
    flatpickr(
      this.element, {
        enableTime: true,
        altInput: true,
        altInputClass: "input-primary",
        disableMobile: true,
        dateFormat: "Z",
        altFormat: "M j, Y h i Kw"
      }
    )
  }
}
