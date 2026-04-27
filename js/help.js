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
    <div class="mb-6">
      <h4 class="text-white font-semibold text-sm mb-2 flex items-center gap-2">
        <span class="w-1.5 h-1.5 bg-glassAero-gold rounded-full flex-shrink-0"></span>
        ${section.heading}
      </h4>
      <ol class="space-y-1.5 ml-4">
        ${section.steps.map((step, i) => `
          <li class="text-gray-300 text-sm leading-relaxed flex gap-2">
            <span class="text-glassAero-gold/60 font-mono text-xs mt-0.5 flex-shrink-0">${i + 1}.</span>
            <span>${step}</span>
          </li>
        `).join('')}
      </ol>
    </div>
  `).join('');
}

function injectHelpUI() {
  const page = document.body.dataset.helpPage;
  if (!page || !HELP_CONTENT[page]) return;

  const content = HELP_CONTENT[page];

  const btn = document.createElement('button');
  btn.id = 'helpBtn';
  btn.title = 'Help';
  btn.className = 'fixed bottom-6 right-6 w-12 h-12 bg-glassAero-gold hover:bg-amber-600 text-black rounded-full shadow-lg flex items-center justify-center text-xl font-bold transition z-40 no-print';
  btn.innerHTML = '<i class="fas fa-question"></i>';
  btn.addEventListener('click', () => {
    document.getElementById('helpModal').classList.remove('hidden');
  });
  document.body.appendChild(btn);

  const modal = document.createElement('div');
  modal.id = 'helpModal';
  modal.className = 'fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 hidden overflow-y-auto p-4';
  modal.innerHTML = `
    <div class="stat-card rounded-2xl p-8 max-w-2xl w-full mx-4 max-h-[85vh] overflow-y-auto my-auto relative">
      <button id="helpCloseBtn" class="absolute top-4 right-4 w-8 h-8 text-gray-400 hover:text-white transition flex items-center justify-center rounded-lg hover:bg-white/10" title="Close">
        <i class="fas fa-times text-lg"></i>
      </button>
      <div class="flex items-center gap-3 mb-2">
        <div class="w-10 h-10 bg-glassAero-gold/20 rounded-lg flex items-center justify-center flex-shrink-0">
          <i class="fas fa-circle-question text-glassAero-gold text-lg"></i>
        </div>
        <h3 class="text-xl font-bold text-white">${content.title} — Help</h3>
      </div>
      <p class="text-gray-400 text-sm mb-6 ml-[52px]">${content.intro}</p>
      <div class="border-t border-white/10 pt-4">
        ${renderHelpSections(content.sections)}
      </div>
      <div class="border-t border-white/10 pt-4 mt-2">
        <p class="text-gray-500 text-xs text-center">Press Escape or click outside to close</p>
      </div>
    </div>
  `;
  document.body.appendChild(modal);

  modal.addEventListener('click', (e) => {
    if (e.target === modal) modal.classList.add('hidden');
  });
  document.getElementById('helpCloseBtn').addEventListener('click', () => {
    modal.classList.add('hidden');
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !modal.classList.contains('hidden')) {
      modal.classList.add('hidden');
    }
  });
}

document.addEventListener('DOMContentLoaded', injectHelpUI);
