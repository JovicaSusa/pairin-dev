import ReadMore from "@stimulus-components/read-more"

export default class extends ReadMore {
  static targets = ["btn"]

  connect() {
    super.connect()

    this._setupBtn()
  }

  _setupBtn() {
    if (this.contentTarget.scrollHeight <= this.contentTarget.offsetHeight) {
      this.btnTarget.style.display = "none"
    }
  }
}
