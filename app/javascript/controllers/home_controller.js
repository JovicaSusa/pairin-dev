import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nav"]
  static values = {
    navOpened: Boolean
  }

  toggleNav(event) {
    this.navOpenedValue = !this.navOpenedValue
    if (this.navOpenedValue) {
      this.navTarget.classList.remove("hidden")
    } else {
      this.navTarget.classList.add("hidden")
    }
  }
}
