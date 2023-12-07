import { Controller } from "@hotwired/stimulus"

import SlimSelect from 'slim-select'

// Connects to data-controller="searchable-select"
export default class extends Controller {
  connect() {
    new SlimSelect({
      select: '#single'
    })
  }
}
