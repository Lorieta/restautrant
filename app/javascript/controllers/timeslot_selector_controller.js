import { Controller } from "@hotwired/stimulus"

// Controls filtering of timeslot options and availability rows when a table is selected.
export default class extends Controller {
    static targets = ["tableSelect", "timeslotSelect", "availabilityRow"]

    connect() {
        // Cache original options and rows so we can restore when no table is selected
        this.originalOptions = []
        if (this.hasTimeslotSelectTarget) {
            Array.from(this.timeslotSelectTarget.options).forEach(opt => {
                this.originalOptions.push({ value: opt.value, text: opt.text, selected: opt.selected })
            })
        }

        this.originalRows = []
        if (this.hasAvailabilityRowTarget) {
            this.availabilityRowTargets.forEach(row => {
                this.originalRows.push(row)
            })
        }

        if (this.hasTableSelectTarget) {
            this.tableSelectTarget.addEventListener('change', this.onTableChange.bind(this))
        }
    }

    async onTableChange(event) {
        const tableId = event.target.value

        if (!this.hasTimeslotSelectTarget) return

        if (!tableId) {
            // restore original options and show all rows
            this._restoreOptions()
            this._showAllRows()
            return
        }

        try {
            const resp = await fetch(`/reservations/timeslots_for_table?table_id=${encodeURIComponent(tableId)}`)
            if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
            const timeslots = await resp.json()
            const ids = timeslots.map(ts => String(ts.id))

            // rebuild select options: keep prompt first, then returned timeslots
            this._replaceOptions(timeslots)

            // hide availability rows that are not in the returned timeslot ids
            if (this.hasAvailabilityRowTarget) {
                this.availabilityRowTargets.forEach(row => {
                    const rowId = row.getAttribute('data-timeslot-id')
                    if (ids.includes(rowId)) {
                        row.style.display = ''
                    } else {
                        row.style.display = 'none'
                    }
                })
            }
        } catch (err) {
            // On error, fall back to showing everything
            console.error('Error fetching timeslots for table:', err)
            this._restoreOptions()
            this._showAllRows()
        }
    }

    _replaceOptions(timeslots) {
        // Keep the prompt option if present
        const select = this.timeslotSelectTarget
        const promptOption = Array.from(select.options).find(opt => opt.value === "")
        select.innerHTML = ''
        if (promptOption) select.appendChild(promptOption)

        timeslots.forEach(ts => {
            const opt = document.createElement('option')
            opt.value = ts.id
            opt.text = ts.label
            select.appendChild(opt)
        })
    }

    _restoreOptions() {
        const select = this.timeslotSelectTarget
        select.innerHTML = ''
        this.originalOptions.forEach(o => {
            const opt = document.createElement('option')
            opt.value = o.value
            opt.text = o.text
            if (o.selected) opt.selected = true
            select.appendChild(opt)
        })
    }

    _showAllRows() {
        if (!this.hasAvailabilityRowTarget) return
        this.availabilityRowTargets.forEach(row => row.style.display = '')
    }
}
