// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import DatepickerController from "./datepicker_controller"
application.register("datepicker", DatepickerController)

import HomeController from "./home_controller"
application.register("home", HomeController)

import RemovalsController from "./removals_controller"
application.register("removals", RemovalsController)

import NestedForm from "stimulus-rails-nested-form"
application.register("nested-form", NestedForm)

import SearchableSelectController from "./searchable_select_controller"
application.register("searchable-select", SearchableSelectController)

import ReadMore from "./read_more_controller"
application.register('read-more', ReadMore)

import HwComboboxController from "@josefarias/hotwire_combobox"
application.register("hw-combobox", HwComboboxController)

import Dropdown from '@stimulus-components/dropdown'
application.register('dropdown', Dropdown)
