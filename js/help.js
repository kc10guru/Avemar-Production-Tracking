// Contextual Help System
// Auto-injects a floating "?" button and modal with page-specific help content

const HELP_CONTENT = {

  dashboard: {
    title: 'Dashboard',
    intro: 'This is your production overview — a real-time snapshot of everything happening on the shop floor.',
    sections: [
      {
        heading: 'Stat Cards',
        steps: [
          'The top row shows key metrics: active work orders, completed this month, on hold, total parts, and low-stock alerts.',
          'Click any stat card to jump directly to the relevant page with filters applied.'
        ]
      },
      {
        heading: 'Production Pipeline',
        steps: [
          'Each column represents one of the 15 production stages.',
          'The number badge shows how many work orders are currently at that stage.',
          'Click a stage to see the work orders in it.'
        ]
      },
      {
        heading: 'Recent Work Orders',
        steps: [
          'Shows the most recently updated work orders.',
          'Click any row to open its detail page.'
        ]
      },
      {
        heading: 'Low Stock Alerts',
        steps: [
          'Lists subcomponents that are at or below their reorder point.',
          'Click "View All Inventory" to manage stock levels.'
        ]
      },
      {
        heading: 'Report an Issue',
        steps: [
          'Click the "Report Issue" button to submit a support ticket.',
          'Select the page the issue is on, choose a type (Bug or Feature Request), and describe the problem.'
        ]
      }
    ]
  },

  workOrders: {
    title: 'Work Orders',
    intro: 'View, search, and filter all windshield repair work orders.',
    sections: [
      {
        heading: 'Finding a Work Order',
        steps: [
          'Use the search bar to find by WO number, customer name, or part number.',
          'Filter by Status (In Progress, Completed, On Hold) and/or by Stage.',
          'Filter by Part Number to see only orders for a specific windshield.',
          'Click "Clear" to reset all filters.'
        ]
      },
      {
        heading: 'Opening a Work Order',
        steps: [
          'Click any row in the table to open its detail page.'
        ]
      },
      {
        heading: 'Creating Work Orders',
        steps: [
          'Click "New Work Order" to create a single order manually.',
          'Admins can click "Import" to bulk-import orders from an Excel spreadsheet.'
        ]
      }
    ]
  },

  workOrderDetail: {
    title: 'Work Order Detail',
    intro: 'This is the main workspace for a single work order — advance stages, manage documents, view parts issued, and track history.',
    sections: [
      {
        heading: 'Production Progress',
        steps: [
          'The progress bar across the top shows which stage this order is at.',
          'Green stages are completed, the gold stage is current, and gray stages are upcoming.',
          'Skipped stages (set during Inspection) appear with a skip icon.'
        ]
      },
      {
        heading: 'Advancing to the Next Stage',
        steps: [
          'Click the "Advance Stage" button when the current stage\'s work is done.',
          'At Stage 3 (Inspection), you will be asked to select which stages to skip for this order.',
          'If the stage has BOM parts assigned, you\'ll review the parts to be issued before confirming.',
          'Parts are automatically deducted from inventory when you advance.'
        ]
      },
      {
        heading: 'Placing an Order On Hold',
        steps: [
          'Click "Hold" and enter a reason to pause the order.',
          'The order will show a red "ON HOLD" banner.',
          'Click "Resume" to take it off hold and continue production.'
        ]
      },
      {
        heading: 'Documents',
        steps: [
          'Click "Upload" or drag-and-drop files into the drop zone.',
          'Accepted formats: PDF, PNG, JPG, GIF, WEBP, and HEIC (iPhone photos).',
          'iPhone photos are automatically converted to JPG for compatibility.',
          'Hover over a document to view or delete it.'
        ]
      },
      {
        heading: 'Editing Order Details',
        steps: [
          'Click the pencil icon next to "Order Details" to edit fields.',
          'You can change the part number — the system will reverse previously issued parts and re-issue for the new BOM.',
          'Click "Save Changes" when done.'
        ]
      },
      {
        heading: 'Other Actions',
        steps: [
          '"Print Barcode" generates a barcode label for the WO number.',
          '"Print" creates a print-friendly view of the entire order.',
          '"Go Back" (when visible) reverts the order to the previous stage.',
          'Admins can "Delete" a work order permanently.'
        ]
      }
    ]
  },

  newRepairOrder: {
    title: 'New Work Order',
    intro: 'Create a new windshield repair work order. Fields marked with * are required.',
    sections: [
      {
        heading: 'Required Fields',
        steps: [
          'WO Number — must be unique. This is what gets printed on the barcode.',
          'Customer Name — the company or individual the windshield is for.'
        ]
      },
      {
        heading: 'Windshield Info',
        steps: [
          'Select a Part Number from the dropdown — these come from the Settings page.',
          'If the part number you need isn\'t listed, an admin must add it in Settings first.',
          'Serial Number, Aircraft info, and Notes are optional but helpful for tracking.'
        ]
      },
      {
        heading: 'After Creating',
        steps: [
          'The order starts at Stage 1 automatically.',
          'You\'ll be redirected to the Work Order Detail page to begin production.'
        ]
      }
    ]
  },

  bom: {
    title: 'Bill of Materials (BOM)',
    intro: 'Define which subcomponents are needed for each windshield part number, and at which production stage they should be issued.',
    sections: [
      {
        heading: 'How BOM Works',
        steps: [
          'Each windshield part number has its own BOM — a list of subcomponents and quantities needed at specific stages.',
          'When a work order advances through a stage, the BOM parts for that stage are automatically deducted from inventory.'
        ]
      },
      {
        heading: 'Setting Up a New Windshield\'s BOM',
        steps: [
          'First, make sure the windshield part number exists — add it in the Settings page if needed.',
          'Next, make sure all required subcomponents exist — add them in the Inventory page if needed.',
          'Then come here, select the windshield from the dropdown, and click "Add Item" for each subcomponent.',
          'For each item: select the subcomponent, choose which stage it\'s issued at, and set the quantity needed.'
        ]
      },
      {
        heading: 'Editing the BOM',
        steps: [
          'Click the pencil icon on any BOM line to change its stage, quantity, or notes.',
          'Click the trash icon to remove a line item from the BOM.',
          'Changes take effect on future stage advances — already-issued parts are not affected.'
        ]
      },
      {
        heading: 'Important',
        steps: [
          'The subcomponent dropdown shows ALL parts from the Inventory page. If the part you need isn\'t listed, go to Inventory and add it first.',
          'A subcomponent can appear at multiple stages if needed (e.g., sealant at Stage 5 and Stage 12).'
        ]
      }
    ]
  },

  inventory: {
    title: 'Inventory (Subcomponents)',
    intro: 'Manage the parts and materials used in windshield production. These are the subcomponents that get assigned to BOMs.',
    sections: [
      {
        heading: 'Adding a New Subcomponent',
        steps: [
          'Click "Add Part" to create a new subcomponent.',
          'Enter a part number, description, category, unit of measure, and quantity on hand.',
          'Set a reorder point to trigger low-stock alerts on the dashboard.',
          'After adding here, the part becomes available in the BOM page for assignment to windshield part numbers.'
        ]
      },
      {
        heading: 'Receiving Stock',
        steps: [
          'Click "Receive Stock" when new inventory arrives.',
          'Select the part and enter the quantity received — it will be added to the current on-hand count.'
        ]
      },
      {
        heading: 'Filtering & Monitoring',
        steps: [
          'Use the Category dropdown to filter by type (Glass, Electrical, Seals, Hardware, Consumable, General).',
          'Check "Low stock only" to see parts at or below their reorder point.',
          '"Projected Available" accounts for parts committed to active work orders that haven\'t been issued yet.'
        ]
      },
      {
        heading: 'Editing a Part',
        steps: [
          'Click the edit icon on any row to update its details.',
          'You can change the description, category, reorder point, cost, supplier, and lead time.'
        ]
      }
    ]
  },

  settings: {
    title: 'Settings',
    intro: 'Configure windshield part numbers, production stage time limits, business hours, and email notifications. Admin access required.',
    sections: [
      {
        heading: 'Adding a New Windshield Part Number',
        steps: [
          'Click "Add" in the Windshield Part Numbers section.',
          'Enter the part number and an optional description, then save.',
          'After adding the part number here, go to Inventory to add any new subcomponents it needs.',
          'Then go to the BOM page to define which subcomponents are used at each stage.'
        ]
      },
      {
        heading: 'Complete Workflow for a New Windshield',
        steps: [
          'Step 1: Add the windshield part number here in Settings.',
          'Step 2: Go to Inventory — add any subcomponents (materials/parts) that don\'t already exist.',
          'Step 3: Go to BOM — select the new windshield and add each subcomponent with its stage and quantity.',
          'Now the windshield is ready to be used in work orders.'
        ]
      },
      {
        heading: 'Stage Time Limits',
        steps: [
          'Set the expected number of hours for each production stage.',
          'Orders exceeding this time are flagged as "late" on the dashboard.',
          'Time is calculated using business hours only (see below).'
        ]
      },
      {
        heading: 'Business Hours',
        steps: [
          'Define the start and end of the work day.',
          'Stage duration calculations and late flags only count hours within this window.',
          'Weekends and hours outside this range are excluded.'
        ]
      },
      {
        heading: 'Email Notifications (EmailJS)',
        steps: [
          'Configure EmailJS to send email notifications for support tickets.',
          'Enter your Service ID, Template ID, and Public Key from your EmailJS account.',
          'Click "Save Changes" to apply.'
        ]
      }
    ]
  },

  reports: {
    title: 'Reports',
    intro: 'Generate production and inventory reports. All reports can be printed.',
    sections: [
      {
        heading: 'Report Types',
        steps: [
          'Weekly — shows production activity for the current week: orders started, completed, in progress, and stage-by-stage breakdown.',
          'Projected Inventory — forecasts which parts will be needed for active orders and highlights potential shortages.',
          'Quarterly — production trends over the past 3 months with a chart.',
          'Annual — full-year overview with monthly breakdown and charts.'
        ]
      },
      {
        heading: 'Generating a Report',
        steps: [
          'Click the tab for the report type you want.',
          'Click "Generate" if the report doesn\'t load automatically.',
          'Click "Print Report" to open a print-friendly version.'
        ]
      }
    ]
  },

  import: {
    title: 'Import Work Orders',
    intro: 'Bulk-import work orders from an Excel spreadsheet. Admin access required.',
    sections: [
      {
        heading: 'Step 1: Download the Template',
        steps: [
          'Click "Download Template" to get an Excel file with the correct column headers.',
          'The template includes an instructions row — delete it before uploading.'
        ]
      },
      {
        heading: 'Step 2: Fill In the Data',
        steps: [
          'WO Number (required) — must be unique.',
          'Customer, Contract, Part Number, Serial Number, Aircraft — fill in as needed.',
          'Stage columns (Y/N) — mark "Y" for stages that need to be performed, "N" to skip.',
          'Stage 1 and Stage 15 are always required and cannot be skipped.'
        ]
      },
      {
        heading: 'Step 3: Upload & Import',
        steps: [
          'Click "Choose File" and select your filled-in Excel file.',
          'The system previews all rows, marking valid ones in green and errors in red.',
          'Fix any errors in your spreadsheet and re-upload, or click "Import All Valid" to import the good rows.',
          'Imported orders start at Stage 1 automatically.'
        ]
      }
    ]
  },

  scan: {
    title: 'Scan & Advance',
    intro: 'Quickly look up a work order by scanning its barcode or typing the WO number, then advance it to the next stage.',
    sections: [
      {
        heading: 'How to Use',
        steps: [
          'Scan a barcode with a USB or Bluetooth scanner — the WO number fills in automatically.',
          'Or type the WO number manually and click "Lookup" (or press Enter).',
          'The system shows the order\'s current stage and status.',
          'Click "Advance" to move it to the next stage.',
          'If the stage has BOM parts, you\'ll confirm the parts to be issued before advancing.'
        ]
      },
      {
        heading: 'Tips',
        steps: [
          'This page is designed for tablets and mobile devices on the shop floor.',
          'After advancing, the input clears so you can scan the next order immediately.',
          'If multiple orders match, you\'ll see a list to choose from.'
        ]
      }
    ]
  },

  supportTickets: {
    title: 'Support Tickets',
    intro: 'View and manage issues reported by users. Admin access required.',
    sections: [
      {
        heading: 'Viewing Tickets',
        steps: [
          'The stat cards at the top show counts by status: Open, In Progress, Resolved, and total.',
          'Click a stat card to filter the list to that status.',
          'Use the Status and Type dropdowns to filter further.'
        ]
      },
      {
        heading: 'Managing a Ticket',
        steps: [
          'Click any row to open the ticket detail.',
          'Review the description, page, and type.',
          'Update the status as you work on the issue.'
        ]
      },
      {
        heading: 'Where Do Tickets Come From?',
        steps: [
          'Users submit tickets from the "Report Issue" button on the Dashboard.',
          'Each ticket captures the page, type (Bug or Feature Request), and a description.'
        ]
      }
    ]
  }
};

function renderHelpSections(sections) {
  return sections.map(section => `
    <div style="margin-bottom:1.5rem">
      <h4 style="color:#fff;font-weight:600;font-size:.9rem;margin-bottom:.5rem;display:flex;align-items:center;gap:.5rem">
        <span style="width:6px;height:6px;background:#f59e0b;border-radius:50%;flex-shrink:0"></span>
        ${section.heading}
      </h4>
      <ol style="margin:0;padding-left:1rem;list-style:none">
        ${section.steps.map((step, i) => `
          <li style="color:#d1d5db;font-size:.875rem;line-height:1.6;display:flex;gap:.5rem;margin-bottom:.35rem">
            <span style="color:rgba(245,158,11,0.6);font-family:monospace;font-size:.75rem;margin-top:2px;flex-shrink:0">${i + 1}.</span>
            <span>${step}</span>
          </li>
        `).join('')}
      </ol>
    </div>
  `).join('');
}

function injectHelpStyle() {
  const style = document.createElement('style');
  style.textContent = `
    #helpBtn { position:fixed; bottom:1.5rem; right:1.5rem; width:48px; height:48px; background:#f59e0b; color:#000;
      border:none; border-radius:50%; box-shadow:0 4px 12px rgba(0,0,0,0.3); display:flex; align-items:center;
      justify-content:center; font-size:1.25rem; font-weight:700; cursor:pointer; z-index:9998; transition:background .2s; }
    #helpBtn:hover { background:#d97706; }
    #helpOverlay { position:fixed; inset:0; background:rgba(0,0,0,0.6); backdrop-filter:blur(4px);
      display:flex; align-items:center; justify-content:center; z-index:9999; overflow-y:auto; padding:1rem; }
    #helpOverlay.help-hidden { display:none; }
    #helpCard { background:linear-gradient(145deg,#1e293b 0%,#0f172a 100%); border:1px solid rgba(255,255,255,0.1);
      border-radius:1rem; padding:2rem; max-width:640px; width:100%; margin:auto; max-height:85vh;
      overflow-y:auto; position:relative; color:#fff; }
    #helpCloseBtn { position:absolute; top:1rem; right:1rem; width:32px; height:32px; background:transparent;
      border:none; color:#9ca3af; cursor:pointer; border-radius:8px; display:flex; align-items:center;
      justify-content:center; font-size:1.1rem; transition:all .2s; }
    #helpCloseBtn:hover { color:#fff; background:rgba(255,255,255,0.1); }
    @media print { #helpBtn { display:none !important; } #helpOverlay { display:none !important; } }
  `;
  document.head.appendChild(style);
}

function injectHelpUI() {
  const page = document.body.dataset.helpPage;
  if (!page || !HELP_CONTENT[page]) return;

  const content = HELP_CONTENT[page];

  injectHelpStyle();

  const btn = document.createElement('button');
  btn.id = 'helpBtn';
  btn.title = 'Help';
  btn.innerHTML = '<i class="fas fa-question"></i>';
  btn.addEventListener('click', () => {
    document.getElementById('helpOverlay').classList.remove('help-hidden');
  });
  document.body.appendChild(btn);

  const overlay = document.createElement('div');
  overlay.id = 'helpOverlay';
  overlay.className = 'help-hidden';
  overlay.innerHTML = `
    <div id="helpCard">
      <button id="helpCloseBtn" title="Close"><i class="fas fa-times"></i></button>
      <div style="display:flex;align-items:center;gap:.75rem;margin-bottom:.5rem">
        <div style="width:40px;height:40px;background:rgba(245,158,11,0.2);border-radius:8px;display:flex;align-items:center;justify-content:center;flex-shrink:0">
          <i class="fas fa-circle-question" style="color:#f59e0b;font-size:1.1rem"></i>
        </div>
        <h3 style="font-size:1.25rem;font-weight:700;margin:0">${content.title} — Help</h3>
      </div>
      <p style="color:#9ca3af;font-size:.875rem;margin:0 0 1.5rem 52px">${content.intro}</p>
      <div style="border-top:1px solid rgba(255,255,255,0.1);padding-top:1rem">
        ${renderHelpSections(content.sections)}
      </div>
      <div style="border-top:1px solid rgba(255,255,255,0.1);padding-top:1rem;margin-top:.5rem">
        <p style="color:#6b7280;font-size:.75rem;text-align:center;margin:0">Press Escape or click outside to close</p>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay.classList.add('help-hidden');
  });
  document.getElementById('helpCloseBtn').addEventListener('click', () => {
    overlay.classList.add('help-hidden');
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !overlay.classList.contains('help-hidden')) {
      overlay.classList.add('help-hidden');
    }
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', injectHelpUI);
} else {
  injectHelpUI();
}
