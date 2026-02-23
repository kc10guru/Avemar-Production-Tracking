// New Repair Order form logic

async function loadForm() {
  const parts = await db.getProductionParts();
  const partSelect = document.getElementById('partNumber');
  parts.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p.partNumber;
    opt.textContent = `${p.partNumber} — ${p.description}`;
    partSelect.appendChild(opt);
  });

  // Default date received to today
  const today = new Date().toISOString().split('T')[0];
  document.getElementById('dateReceived').value = today;
}

function showStatus(message, isError = false) {
  const el = document.getElementById('statusMessage');
  el.className = `p-4 rounded-xl text-sm ${isError
    ? 'bg-red-500/20 border border-red-500/30 text-red-400'
    : 'bg-emerald-500/20 border border-emerald-500/30 text-emerald-400'}`;
  el.innerHTML = `<i class="fas fa-${isError ? 'exclamation-circle' : 'check-circle'} mr-2"></i>${message}`;
  el.classList.remove('hidden');
}

async function handleSubmit(event) {
  event.preventDefault();

  const btn = document.getElementById('submitBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Creating...';

  try {
    const order = {
      customerName: document.getElementById('customerName').value.trim(),
      partNumber: document.getElementById('partNumber').value,
      serialNumber: document.getElementById('serialNumber').value.trim(),
      aircraftTailNumber: document.getElementById('aircraftTailNumber').value.trim() || null,
      aircraftType: document.getElementById('aircraftType').value.trim() || null,
      contractType: document.getElementById('contractType').value,
      shippingAddress: document.getElementById('shippingAddress').value.trim() || null,
      purchaseOrder: document.getElementById('purchaseOrder').value.trim() || null,
      contactName: document.getElementById('contactName').value.trim() || null,
      contactEmail: document.getElementById('contactEmail').value.trim() || null,
      contactPhone: document.getElementById('contactPhone').value.trim() || null,
      dateReceived: document.getElementById('dateReceived').value || new Date().toISOString(),
      expectedCompletion: document.getElementById('expectedCompletion').value || null,
      notes: document.getElementById('notes').value.trim() || null,
      currentStage: 1,
      status: 'In Progress'
    };

    const saved = await db.saveRepairOrder(order);
    if (!saved) {
      showStatus('Failed to create repair order. Please try again.', true);
      btn.disabled = false;
      btn.innerHTML = '<i class="fas fa-save mr-2"></i>Create Repair Order';
      return;
    }

    // Create initial stage history entry (Receiving)
    const stages = await db.getProductionStages();
    const firstStage = stages.find(s => s.stageNumber === 1);
    await db.addStageEntry({
      repairOrderId: saved.id,
      stageNumber: 1,
      stageName: firstStage ? firstStage.stageName : 'Receiving',
      enteredAt: new Date().toISOString()
    });

    showStatus(`Repair order ${saved.roNumber} created successfully! Redirecting...`);

    setTimeout(() => {
      window.location.href = `repair-order-detail.html?id=${saved.id}`;
    }, 1500);

  } catch (error) {
    console.error('Error creating repair order:', error);
    showStatus('An error occurred. Please try again.', true);
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-save mr-2"></i>Create Repair Order';
  }
}

document.addEventListener('DOMContentLoaded', async () => {
  await initializeAuth();
  await loadForm();
});
