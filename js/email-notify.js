// Email Notification via EmailJS (browser-side, fails silently if unavailable)

window.emailNotify = {
  _config: null,

  async loadConfig() {
    if (this._config) return this._config;
    try {
      const saved = await db.getAppSetting('email_config');
      this._config = saved || null;
    } catch (e) { this._config = null; }
    return this._config;
  },

  isConfigured() {
    return this._config &&
      this._config.publicKey &&
      this._config.serviceId &&
      this._config.templateId &&
      this._config.notifyEmail;
  },

  async send(templateParams) {
    try {
      const config = await this.loadConfig();
      if (!config || !this.isConfigured()) return;
      if (typeof emailjs === 'undefined') return;

      await emailjs.send(config.serviceId, config.templateId, templateParams, config.publicKey);
      console.log('Email notification sent');
    } catch (err) {
      console.warn('Email notification failed (non-blocking):', err);
    }
  },

  async notifyNewTicket(ticket) {
    const config = await this.loadConfig();
    if (!config) return;

    await this.send({
      to_email: config.notifyEmail,
      from_name: 'Glass Aero Tracker',
      subject: `[${ticket.ticketNumber}] New ${ticket.type}: ${ticket.subject}`,
      message: `
        <h2>New Support Ticket</h2>
        <table style="border-collapse:collapse;width:100%;max-width:600px;">
          <tr><td style="padding:8px;color:#888;width:120px;">Ticket</td><td style="padding:8px;font-weight:bold;">${ticket.ticketNumber}</td></tr>
          <tr><td style="padding:8px;color:#888;">Type</td><td style="padding:8px;">${ticket.type}</td></tr>
          <tr><td style="padding:8px;color:#888;">Priority</td><td style="padding:8px;">${ticket.priority}</td></tr>
          <tr><td style="padding:8px;color:#888;">Reporter</td><td style="padding:8px;">${ticket.reporterEmail}</td></tr>
          <tr><td style="padding:8px;color:#888;">Page</td><td style="padding:8px;">${ticket.pageUrl || 'Not specified'}</td></tr>
          <tr><td style="padding:8px;color:#888;">Subject</td><td style="padding:8px;font-weight:bold;">${ticket.subject}</td></tr>
          <tr><td style="padding:8px;color:#888;vertical-align:top;">Description</td><td style="padding:8px;white-space:pre-wrap;">${ticket.description}</td></tr>
        </table>
      `
    });
  },

  async notifyTicketResolved(ticket) {
    if (!ticket.reporterEmail) return;

    await this.send({
      to_email: ticket.reporterEmail,
      from_name: 'Glass Aero Tracker',
      subject: `[${ticket.ticketNumber}] Resolved: ${ticket.subject}`,
      message: `
        <h2>Your Support Ticket Has Been Resolved</h2>
        <table style="border-collapse:collapse;width:100%;max-width:600px;">
          <tr><td style="padding:8px;color:#888;width:120px;">Ticket</td><td style="padding:8px;font-weight:bold;">${ticket.ticketNumber}</td></tr>
          <tr><td style="padding:8px;color:#888;">Subject</td><td style="padding:8px;">${ticket.subject}</td></tr>
          <tr><td style="padding:8px;color:#888;vertical-align:top;">Resolution</td><td style="padding:8px;white-space:pre-wrap;">${ticket.resolutionNotes || 'Issue has been resolved.'}</td></tr>
        </table>
        <p style="margin-top:16px;color:#888;">If you have further questions, please submit a new ticket.</p>
      `
    });
  }
};
