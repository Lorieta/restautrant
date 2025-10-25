import { Controller } from "@hotwired/stimulus"

// Provides a reusable confirmation modal for CRUD operations.
export default class extends Controller {
    static targets = ["backdrop", "title", "message", "confirmButton", "cancelButton"]
    static values = {
        defaultTitle: { type: String, default: "Confirm Action" },
        defaultMessage: { type: String, default: "Are you sure you want to continue?" },
        defaultConfirmText: { type: String, default: "Confirm" },
        defaultCancelText: { type: String, default: "Cancel" }
    }

    connect() {
        this.confirmButtonBaseClass = this.confirmButtonTarget.className
        this.cancelButtonBaseClass = this.cancelButtonTarget.className
        this.handleKeydown = this.handleKeydown.bind(this)
        document.addEventListener("keydown", this.handleKeydown)
    }

    disconnect() {
        document.removeEventListener("keydown", this.handleKeydown)
    }

    ask(event) {
        const trigger = event.currentTarget

        if (trigger.dataset.confirmModalBypass === "true") {
            delete trigger.dataset.confirmModalBypass
            return
        }

        event.preventDefault()

        this.trigger = trigger
        this.previousFocus = document.activeElement

        const {
            confirmModalTitle,
            confirmModalMessage,
            confirmModalConfirmText,
            confirmModalCancelText,
            confirmModalConfirmClass,
            confirmModalCancelClass
        } = trigger.dataset

        this.titleTarget.textContent = confirmModalTitle || this.defaultTitleValue
        this.messageTarget.textContent = confirmModalMessage || this.defaultMessageValue
        this.confirmButtonTarget.textContent = confirmModalConfirmText || this.defaultConfirmTextValue
        this.cancelButtonTarget.textContent = confirmModalCancelText || this.defaultCancelTextValue

        this.confirmButtonTarget.className = confirmModalConfirmClass || this.confirmButtonBaseClass
        this.cancelButtonTarget.className = confirmModalCancelClass || this.cancelButtonBaseClass

        this.open()
    }

    open() {
        if (this.isOpen()) return

        this.backdropTarget.hidden = false
        requestAnimationFrame(() => {
            this.backdropTarget.classList.add("is-visible")
            this.confirmButtonTarget.focus()
        })
    }

    close() {
        if (!this.isOpen()) return

        this.backdropTarget.classList.remove("is-visible")
        const handleTransitionEnd = () => {
            this.backdropTarget.hidden = true
            this.backdropTarget.removeEventListener("transitionend", handleTransitionEnd)
        }
        this.backdropTarget.addEventListener("transitionend", handleTransitionEnd)

        if (this.previousFocus && typeof this.previousFocus.focus === "function") {
            this.previousFocus.focus()
        }

        this.trigger = null
    }

    confirm(event) {
        event.preventDefault()
        const trigger = this.trigger
        this.close()

        if (!trigger) return

        trigger.dataset.confirmModalBypass = "true"

        if ((trigger.tagName === "BUTTON" || trigger.tagName === "INPUT") && trigger.form) {
            trigger.form.requestSubmit(trigger)
        } else if (trigger.tagName === "FORM") {
            trigger.requestSubmit()
        } else if (trigger.tagName === "A") {
            const method = trigger.dataset.turboMethod || trigger.dataset.method
            if (method && method.toLowerCase() !== "get") {
                this.submitLinkWithMethod(trigger, method)
            } else {
                window.location.href = trigger.href
            }
        } else {
            trigger.click()
        }

        delete trigger.dataset.confirmModalBypass
    }

    submitLinkWithMethod(trigger, method) {
        const form = document.createElement("form")
        form.method = "post"
        form.action = trigger.href
        form.style.display = "none"

        const target = trigger.getAttribute("target")
        if (target) form.setAttribute("target", target)

        const turboFrame = trigger.dataset.turboFrame
        if (turboFrame) form.setAttribute("data-turbo-frame", turboFrame)

        const turboPreference = trigger.dataset.turbo
        if (typeof turboPreference !== "undefined") {
            form.dataset.turbo = turboPreference
        }

        const normalizedMethod = method.toUpperCase()
        if (normalizedMethod !== "POST") {
            const methodInput = document.createElement("input")
            methodInput.type = "hidden"
            methodInput.name = "_method"
            methodInput.value = normalizedMethod
            form.appendChild(methodInput)
        }

        const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
        const csrfParam = document.querySelector("meta[name='csrf-param']")?.getAttribute("content")

        if (csrfParam && csrfToken) {
            const csrfInput = document.createElement("input")
            csrfInput.type = "hidden"
            csrfInput.name = csrfParam
            csrfInput.value = csrfToken
            form.appendChild(csrfInput)
        }

        document.body.appendChild(form)
        form.requestSubmit()
        form.addEventListener("turbo:submit-end", () => form.remove(), { once: true })
        form.addEventListener("submit", () => {
            if (!window.Turbo) form.remove()
        }, { once: true })
    }

    cancel(event) {
        event.preventDefault()
        this.close()
    }

    handleKeydown(event) {
        if (!this.isOpen()) return

        if (event.key === "Escape") {
            event.preventDefault()
            this.close()
        }
    }

    isOpen() {
        return !this.backdropTarget.hidden
    }
}
