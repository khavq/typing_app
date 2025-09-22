export default {
  mounted() {
    // Focus the input element when it's mounted
    this.el.focus()

    // Handle value updates from LiveView
    this.handleEvent("sync_input", (payload) => {
      this.el.value = payload.value
    })
    
    // Handle explicit refocus requests (e.g., after sound toggle)
    this.handleEvent("refocus_typing", (_) => {
      // Use setTimeout to ensure DOM is fully updated
      setTimeout(() => {
        this.el.focus()
        console.log('Refocused typing input after sound toggle')
      }, 10)
    })
  },

  updated() {
    // Keep focus on the input field
    this.el.focus()
  }
}
