// Supabase Configuration for Avemar Production Tracking
(function() {
  const SUPABASE_URL = 'https://avemar-db.duckdns.org';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE3OTk1MzU2MDB9.Z7TQV4VxWaN_eGuMgccr_8q55wyu2rjBQhlwU_w3xJE';

  if (!window.supabase || !window.supabase.createClient) {
    console.error('Supabase library not loaded. Check your internet connection.');
    return;
  }

  window.supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  function toCamelCase(obj) {
    if (Array.isArray(obj)) return obj.map(toCamelCase);
    if (obj !== null && typeof obj === 'object') {
      return Object.keys(obj).reduce((result, key) => {
        const camelKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
        result[camelKey] = toCamelCase(obj[key]);
        return result;
      }, {});
    }
    return obj;
  }

  function toSnakeCase(obj) {
    if (Array.isArray(obj)) return obj.map(toSnakeCase);
    if (obj !== null && typeof obj === 'object') {
      return Object.keys(obj).reduce((result, key) => {
        const snakeKey = key.replace(/([A-Z])/g, '_$1').toLowerCase();
        result[snakeKey] = toSnakeCase(obj[key]);
        return result;
      }, {});
    }
    return obj;
  }

  // Generate sequential RO number: RO-YYYYMMDD-0001, 0002, etc.
  async function generateRoNumber() {
    const now = new Date();
    const datePart = now.toISOString().slice(0, 10).replace(/-/g, '');
    const prefix = `RO-${datePart}-`;

    const { data } = await window.supabaseClient
      .from('repair_orders')
      .select('ro_number')
      .like('ro_number', `${prefix}%`)
      .order('ro_number', { ascending: false })
      .limit(1);

    let seq = 1;
    if (data && data.length > 0) {
      const lastNum = parseInt(data[0].ro_number.split('-').pop(), 10);
      if (!isNaN(lastNum)) seq = lastNum + 1;
    }

    return `${prefix}${String(seq).padStart(4, '0')}`;
  }

  window.db = {

    // ─── Production Parts ───────────────────────────────────
    async getProductionParts() {
      const { data, error } = await window.supabaseClient
        .from('production_parts').select('*')
        .eq('is_active', true)
        .order('part_number');
      if (error) { console.error('Error fetching production parts:', error); return []; }
      return toCamelCase(data);
    },

    async saveProductionPart(part) {
      const snakeData = toSnakeCase(part);
      delete snakeData.id;
      const { data, error } = await window.supabaseClient
        .from('production_parts').insert(snakeData).select();
      if (error) { console.error('Error saving production part:', error); return null; }
      return toCamelCase(data[0]);
    },

    async updateProductionPart(id, part) {
      const snakeData = toSnakeCase(part);
      delete snakeData.id;
      const { data, error } = await window.supabaseClient
        .from('production_parts').update(snakeData).eq('id', id).select();
      if (error) { console.error('Error updating production part:', error); return null; }
      return toCamelCase(data[0]);
    },

    // ─── Production Stages ──────────────────────────────────
    async getProductionStages() {
      const { data, error } = await window.supabaseClient
        .from('production_stages').select('*')
        .eq('is_active', true)
        .order('stage_number');
      if (error) { console.error('Error fetching stages:', error); return []; }
      return toCamelCase(data);
    },

    async updateProductionStage(id, stage) {
      const snakeData = toSnakeCase(stage);
      delete snakeData.id;
      const { data, error } = await window.supabaseClient
        .from('production_stages').update(snakeData).eq('id', id).select();
      if (error) { console.error('Error updating stage:', error); return null; }
      return toCamelCase(data[0]);
    },

    // ─── Repair Orders ──────────────────────────────────────
    async getRepairOrders(filters = {}) {
      let query = window.supabaseClient
        .from('repair_orders').select('*')
        .or('is_archived.is.null,is_archived.eq.false')
        .order('created_at', { ascending: false });

      if (filters.status) query = query.eq('status', filters.status);
      if (filters.currentStage) query = query.eq('current_stage', filters.currentStage);
      if (filters.partNumber) query = query.eq('part_number', filters.partNumber);
      if (filters.search) {
        query = query.or(
          `ro_number.ilike.%${filters.search}%,customer_name.ilike.%${filters.search}%,serial_number.ilike.%${filters.search}%`
        );
      }

      const { data, error } = await query;
      if (error) { console.error('Error fetching repair orders:', error); return []; }
      return toCamelCase(data);
    },

    async getRepairOrder(id) {
      const { data, error } = await window.supabaseClient
        .from('repair_orders').select('*').eq('id', id).single();
      if (error) { console.error('Error fetching repair order:', error); return null; }
      return toCamelCase(data);
    },

    async saveRepairOrder(order) {
      const snakeData = toSnakeCase(order);
      delete snakeData.id;
      if (!snakeData.ro_number) snakeData.ro_number = await generateRoNumber();
      const { data, error } = await window.supabaseClient
        .from('repair_orders').insert(snakeData).select();
      if (error) { console.error('Error saving repair order:', error); return null; }
      return toCamelCase(data[0]);
    },

    async updateRepairOrder(id, order) {
      const snakeData = toSnakeCase(order);
      delete snakeData.id;
      snakeData.updated_at = new Date().toISOString();
      const { data, error } = await window.supabaseClient
        .from('repair_orders').update(snakeData).eq('id', id).select();
      if (error) { console.error('Error updating repair order:', error); return null; }
      return toCamelCase(data[0]);
    },

    async deleteRepairOrder(id) {
      // Reverse all issued parts to restore inventory before deleting
      await this.reverseAllPartsForOrder(id);

      // Delete related records (cascade should handle this, but be explicit)
      await window.supabaseClient.from('hold_history').delete().eq('repair_order_id', id);
      await window.supabaseClient.from('stage_history').delete().eq('repair_order_id', id);

      // Delete documents from storage
      const { data: docs } = await window.supabaseClient
        .from('repair_order_documents').select('file_path').eq('repair_order_id', id);
      if (docs && docs.length > 0) {
        await window.supabaseClient.storage
          .from('repair-order-docs')
          .remove(docs.map(d => d.file_path));
      }
      await window.supabaseClient.from('repair_order_documents').delete().eq('repair_order_id', id);

      const { error } = await window.supabaseClient
        .from('repair_orders').delete().eq('id', id);
      if (error) { console.error('Error deleting repair order:', error); return false; }
      return true;
    },

    async archiveRepairOrder(id) {
      const { error } = await window.supabaseClient
        .from('repair_orders').update({ is_archived: true, updated_at: new Date().toISOString() }).eq('id', id);
      if (error) { console.error('Error archiving repair order:', error); return false; }
      return true;
    },

    // ─── Stage History ──────────────────────────────────────
    async getStageHistory(repairOrderId) {
      const { data, error } = await window.supabaseClient
        .from('stage_history').select('*')
        .eq('repair_order_id', repairOrderId)
        .order('stage_number');
      if (error) { console.error('Error fetching stage history:', error); return []; }
      return toCamelCase(data);
    },

    async addStageEntry(entry) {
      const snakeData = toSnakeCase(entry);
      delete snakeData.id;
      const { data, error } = await window.supabaseClient
        .from('stage_history').insert(snakeData).select();
      if (error) { console.error('Error adding stage entry:', error); return null; }
      return toCamelCase(data[0]);
    },

    async updateStageEntry(id, updates) {
      const snakeData = toSnakeCase(updates);
      delete snakeData.id;
      const { data, error } = await window.supabaseClient
        .from('stage_history').update(snakeData).eq('id', id).select();
      if (error) { console.error('Error updating stage entry:', error); return null; }
      return toCamelCase(data[0]);
    },

    // ─── Subcomponents (Parts Inventory) ────────────────────
    async getSubcomponents(filters = {}) {
      let query = window.supabaseClient
        .from('subcomponents').select('*')
        .eq('is_active', true)
        .order('part_number');

      if (filters.category) query = query.eq('category', filters.category);

      const { data, error } = await query;
      if (error) { console.error('Error fetching subcomponents:', error); return []; }
      return toCamelCase(data);
    },

    async getSubcomponent(id) {
      const { data, error } = await window.supabaseClient
        .from('subcomponents').select('*').eq('id', id).single();
      if (error) { console.error('Error fetching subcomponent:', error); return null; }
      return toCamelCase(data);
    },

    async saveSubcomponent(sub) {
      const snakeData = toSnakeCase(sub);
      delete snakeData.id;
      const { data, error } = await window.supabaseClient
        .from('subcomponents').insert(snakeData).select();
      if (error) { console.error('Error saving subcomponent:', error); return null; }
      return toCamelCase(data[0]);
    },

    async updateSubcomponent(id, sub) {
      const snakeData = toSnakeCase(sub);
      delete snakeData.id;
      snakeData.updated_at = new Date().toISOString();
      const { data, error } = await window.supabaseClient
        .from('subcomponents').update(snakeData).eq('id', id).select();
      if (error) { console.error('Error updating subcomponent:', error); return null; }
      return toCamelCase(data[0]);
    },

    async receiveSubcomponentStock(id, quantityReceived) {
      const current = await this.getSubcomponent(id);
      if (!current) return null;
      const newQty = Number(current.quantityOnHand) + Number(quantityReceived);
      return this.updateSubcomponent(id, { quantityOnHand: newQty });
    },

    async getLowStockSubcomponents() {
      const { data, error } = await window.supabaseClient
        .from('subcomponents').select('*')
        .eq('is_active', true)
        .order('part_number');
      if (error) { console.error('Error fetching subcomponents:', error); return []; }
      const all = toCamelCase(data);
      return all.filter(s => Number(s.quantityOnHand) <= Number(s.reorderPoint));
    },

    // ─── BOM Items ──────────────────────────────────────────
    async getBomItems(productionPartId) {
      const { data, error } = await window.supabaseClient
        .from('bom_items').select('*, subcomponents(*)')
        .eq('production_part_id', productionPartId)
        .eq('is_active', true)
        .order('stage_number');
      if (error) { console.error('Error fetching BOM items:', error); return []; }
      return toCamelCase(data);
    },

    async getBomForStage(productionPartId, stageNumber) {
      const { data, error } = await window.supabaseClient
        .from('bom_items').select('*, subcomponents(*)')
        .eq('production_part_id', productionPartId)
        .eq('stage_number', stageNumber)
        .eq('is_active', true);
      if (error) { console.error('Error fetching BOM for stage:', error); return []; }
      return toCamelCase(data);
    },

    async saveBomItem(item) {
      const snakeData = toSnakeCase(item);
      delete snakeData.id;
      delete snakeData.subcomponents;
      const { data, error } = await window.supabaseClient
        .from('bom_items').insert(snakeData).select();
      if (error) { console.error('Error saving BOM item:', error); return null; }
      return toCamelCase(data[0]);
    },

    async updateBomItem(id, item) {
      const snakeData = toSnakeCase(item);
      delete snakeData.id;
      delete snakeData.subcomponents;
      const { data, error } = await window.supabaseClient
        .from('bom_items').update(snakeData).eq('id', id).select();
      if (error) { console.error('Error updating BOM item:', error); return null; }
      return toCamelCase(data[0]);
    },

    async deleteBomItem(id) {
      const { error } = await window.supabaseClient
        .from('bom_items').update({ is_active: false }).eq('id', id);
      if (error) { console.error('Error deleting BOM item:', error); return false; }
      return true;
    },

    // ─── Parts Issuance ─────────────────────────────────────
    async getPartsIssuance(repairOrderId) {
      const { data, error } = await window.supabaseClient
        .from('parts_issuance').select('*, subcomponents(part_number, description)')
        .eq('repair_order_id', repairOrderId)
        .order('issued_at', { ascending: false });
      if (error) { console.error('Error fetching issuance:', error); return []; }
      return toCamelCase(data);
    },

    async issuePart(issuance) {
      const snakeData = toSnakeCase(issuance);
      delete snakeData.id;

      // Decrement subcomponent inventory
      const sub = await this.getSubcomponent(issuance.subcomponentId);
      if (!sub) return null;
      const newQty = Number(sub.quantityOnHand) - Number(issuance.quantityIssued);
      await this.updateSubcomponent(issuance.subcomponentId, { quantityOnHand: Math.max(0, newQty) });

      const { data, error } = await window.supabaseClient
        .from('parts_issuance').insert(snakeData).select();
      if (error) { console.error('Error issuing part:', error); return null; }
      return toCamelCase(data[0]);
    },

    async reversePartsForStage(repairOrderId, stageNumber) {
      const { data, error } = await window.supabaseClient
        .from('parts_issuance').select('*')
        .eq('repair_order_id', repairOrderId)
        .eq('stage_number', stageNumber);
      if (error) { console.error('Error fetching parts to reverse:', error); return false; }
      if (!data || data.length === 0) return true;

      for (const record of data) {
        const sub = await this.getSubcomponent(record.subcomponent_id);
        if (sub) {
          const restoredQty = Number(sub.quantityOnHand) + Number(record.quantity_issued);
          await this.updateSubcomponent(record.subcomponent_id, { quantityOnHand: restoredQty });
        }
        await window.supabaseClient.from('parts_issuance').delete().eq('id', record.id);
      }
      return true;
    },

    async reverseAllPartsForOrder(repairOrderId) {
      const { data, error } = await window.supabaseClient
        .from('parts_issuance').select('*')
        .eq('repair_order_id', repairOrderId);
      if (error) { console.error('Error fetching parts to reverse:', error); return false; }
      if (!data || data.length === 0) return true;

      for (const record of data) {
        const sub = await this.getSubcomponent(record.subcomponent_id);
        if (sub) {
          const restoredQty = Number(sub.quantityOnHand) + Number(record.quantity_issued);
          await this.updateSubcomponent(record.subcomponent_id, { quantityOnHand: restoredQty });
        }
        await window.supabaseClient.from('parts_issuance').delete().eq('id', record.id);
      }
      return true;
    },

    async changePartNumber(repairOrderId, newPartNumber, currentStage) {
      // 1. Reverse all previously issued parts (restore inventory)
      const reversed = await this.reverseAllPartsForOrder(repairOrderId);
      if (!reversed) return false;

      // 2. Get the order's skipped stages
      const orderData = await this.getRepairOrder(repairOrderId);
      const skippedStages = orderData?.skippedStages || [];

      // 3. Find the new production part and its BOM
      const prodParts = await this.getProductionParts();
      const newProdPart = prodParts.find(p => p.partNumber === newPartNumber);
      if (!newProdPart) {
        console.error('New part number not found in production parts');
        return false;
      }

      // 4. Re-issue BOM parts for completed, non-skipped stages (< currentStage)
      const userId = (await window.supabaseClient.auth.getUser()).data?.user?.id || null;
      const allBom = await this.getBomItems(newProdPart.id);

      for (const item of allBom) {
        if (item.stageNumber < currentStage && !skippedStages.includes(item.stageNumber)) {
          const subId = item.subcomponentId || item.subcomponents?.id;
          if (!subId) continue;
          await this.issuePart({
            repairOrderId: repairOrderId,
            subcomponentId: subId,
            bomItemId: item.id,
            stageNumber: item.stageNumber,
            quantityIssued: Number(item.quantityRequired),
            issuedBy: userId
          });
        }
      }

      // 5. Update the repair order's part number
      const updated = await this.updateRepairOrder(repairOrderId, { partNumber: newPartNumber });
      return !!updated;
    },

    async deleteStageEntry(id) {
      const { error } = await window.supabaseClient
        .from('stage_history').delete().eq('id', id);
      if (error) { console.error('Error deleting stage entry:', error); return false; }
      return true;
    },

    // ─── Hold / Resume ───────────────────────────────────────
    async holdRepairOrder(id, stageNumber, stageName, reason) {
      const userId = (await window.supabaseClient.auth.getUser()).data?.user?.id || null;
      const now = new Date().toISOString();

      const { error: holdError } = await window.supabaseClient
        .from('hold_history').insert({
          repair_order_id: id,
          stage_number: stageNumber,
          stage_name: stageName,
          hold_reason: reason,
          held_by: userId,
          held_at: now
        });
      if (holdError) { console.error('Error creating hold entry:', holdError); return false; }

      const { error } = await window.supabaseClient
        .from('repair_orders').update({
          is_on_hold: true,
          hold_reason: reason,
          hold_stage: stageNumber,
          hold_started_at: now,
          status: 'On Hold',
          updated_at: now
        }).eq('id', id);
      if (error) { console.error('Error putting order on hold:', error); return false; }
      return true;
    },

    async resumeRepairOrder(id) {
      const userId = (await window.supabaseClient.auth.getUser()).data?.user?.id || null;
      const now = new Date().toISOString();

      const { data: openHold } = await window.supabaseClient
        .from('hold_history').select('*')
        .eq('repair_order_id', id)
        .is('resumed_at', null)
        .order('held_at', { ascending: false })
        .limit(1);

      if (openHold && openHold.length > 0) {
        const heldAt = new Date(openHold[0].held_at);
        const hours = window.calculateBusinessHours
          ? window.calculateBusinessHours(heldAt, new Date())
          : Math.round((new Date() - heldAt) / (1000 * 60 * 60) * 10) / 10;
        await window.supabaseClient
          .from('hold_history').update({
            resumed_by: userId,
            resumed_at: now,
            hold_duration_hours: hours
          }).eq('id', openHold[0].id);
      }

      const { error } = await window.supabaseClient
        .from('repair_orders').update({
          is_on_hold: false,
          hold_reason: null,
          hold_stage: null,
          hold_started_at: null,
          status: 'In Progress',
          updated_at: now
        }).eq('id', id);
      if (error) { console.error('Error resuming order:', error); return false; }
      return true;
    },

    async getHoldHistory(repairOrderId) {
      const { data, error } = await window.supabaseClient
        .from('hold_history').select('*')
        .eq('repair_order_id', repairOrderId)
        .order('held_at', { ascending: false });
      if (error) { console.error('Error fetching hold history:', error); return []; }
      return toCamelCase(data);
    },

    // ─── Dashboard Helpers ──────────────────────────────────
    async getDashboardStats() {
      const [orders, stages, allSubs, productionParts] = await Promise.all([
        this.getRepairOrders(),
        this.getProductionStages(),
        this.getSubcomponents(),
        this.getProductionParts()
      ]);

      const active = orders.filter(o => o.status === 'In Progress');
      const completed = orders.filter(o => o.status === 'Completed');
      const onHold = orders.filter(o => o.status === 'On Hold');

      const now = new Date();
      const thisMonth = completed.filter(o => {
        const d = new Date(o.dateCompleted);
        return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
      });

      // Calculate projected needs from all active in-progress orders
      const projectedNeeds = {};
      for (const order of active) {
        const prodPart = productionParts.find(p => p.partNumber === order.partNumber);
        if (!prodPart) continue;
        const skipped = order.skippedStages || [];
        const bomItems = await this.getBomItems(prodPart.id);
        for (const item of bomItems) {
          if (item.stageNumber > order.currentStage && !skipped.includes(item.stageNumber)) {
            const subId = item.subcomponentId || item.subcomponents?.id;
            if (!subId) continue;
            if (!projectedNeeds[subId]) projectedNeeds[subId] = 0;
            projectedNeeds[subId] += Number(item.quantityRequired);
          }
        }
      }

      // Determine low stock using projected availability
      const lowStock = allSubs
        .map(s => {
          const onHand = Number(s.quantityOnHand);
          const projected = projectedNeeds[s.id] || 0;
          const available = onHand - projected;
          return { ...s, projectedNeed: projected, projectedAvailable: available };
        })
        .filter(s => s.projectedAvailable <= Number(s.reorderPoint));

      // Count units per stage, detect late and on-hold items
      const stageMap = stages.map(stage => {
        const unitsInStage = active.filter(o => o.currentStage === stage.stageNumber);
        const holdUnitsInStage = onHold.filter(o => o.currentStage === stage.stageNumber);
        const lateUnits = unitsInStage.filter(o => {
          const history = null;
          return false;
        });
        return {
          ...stage,
          unitCount: unitsInStage.length,
          lateCount: 0,
          holdCount: holdUnitsInStage.length,
          holdUnits: holdUnitsInStage,
          units: [...unitsInStage, ...holdUnitsInStage]
        };
      });

      return {
        totalActive: active.length,
        totalCompleted: completed.length,
        completedThisMonth: thisMonth.length,
        totalOnHold: onHold.length,
        lowStockCount: lowStock.length,
        lowStockItems: lowStock,
        stages: stageMap
      };
    },

    // ─── Repair Order Documents ────────────────────────────
    async getDocuments(repairOrderId) {
      const { data, error } = await window.supabaseClient
        .from('repair_order_documents').select('*')
        .eq('repair_order_id', repairOrderId)
        .order('uploaded_at', { ascending: false });
      if (error) { console.error('Error fetching documents:', error); return []; }
      return toCamelCase(data);
    },

    async uploadDocument(repairOrderId, file, stageNumber) {
      const timestamp = Date.now();
      const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
      const filePath = `${repairOrderId}/${timestamp}_${safeName}`;

      const { error: uploadError } = await window.supabaseClient.storage
        .from('repair-order-docs')
        .upload(filePath, file, { contentType: file.type });
      if (uploadError) { console.error('Error uploading file:', uploadError); return null; }

      const { data, error: dbError } = await window.supabaseClient
        .from('repair_order_documents').insert({
          repair_order_id: repairOrderId,
          file_name: file.name,
          file_path: filePath,
          file_type: file.type,
          file_size: file.size,
          stage_number: stageNumber,
          uploaded_by: (await window.supabaseClient.auth.getUser()).data?.user?.id || null
        }).select();
      if (dbError) { console.error('Error saving document record:', dbError); return null; }
      return toCamelCase(data[0]);
    },

    async deleteDocument(docId, filePath) {
      const { error: storageError } = await window.supabaseClient.storage
        .from('repair-order-docs')
        .remove([filePath]);
      if (storageError) { console.error('Error deleting file from storage:', storageError); }

      const { error: dbError } = await window.supabaseClient
        .from('repair_order_documents').delete().eq('id', docId);
      if (dbError) { console.error('Error deleting document record:', dbError); return false; }
      return true;
    },

    async getDocumentUrl(filePath) {
      const { data, error } = await window.supabaseClient.storage
        .from('repair-order-docs')
        .createSignedUrl(filePath, 3600);
      if (error) { console.error('Error creating signed URL:', error); return null; }
      return data.signedUrl;
    },

    // ─── App Settings ───────────────────────────────────────
    async getAppSetting(key) {
      const { data, error } = await window.supabaseClient
        .from('app_settings').select('value').eq('key', key).single();
      if (error) { return null; }
      return data?.value;
    },

    async saveAppSetting(key, value) {
      const { error } = await window.supabaseClient
        .from('app_settings').upsert({
          key: key,
          value: value,
          updated_at: new Date().toISOString()
        });
      if (error) { console.error('Error saving setting:', error); return false; }
      return true;
    },

    // ─── Realtime Subscriptions ─────────────────────────────
    subscribeToRepairOrders(callback) {
      return window.supabaseClient
        .channel('repair_orders_changes')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'repair_orders' }, callback)
        .subscribe();
    },

    subscribeToSubcomponents(callback) {
      return window.supabaseClient
        .channel('subcomponents_changes')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'subcomponents' }, callback)
        .subscribe();
    }
  };

  // ─── Business Hours Calculator (global) ─────────────────
  const DEFAULT_BIZ_HOURS = {
    openHour: 9, openMinute: 0,
    closeHour: 18, closeMinute: 0,
    timezone: 'America/New_York',
    workDays: [1, 2, 3, 4, 5]
  };

  window.businessHoursConfig = null;

  window.loadBusinessHoursConfig = async function() {
    const saved = await window.db.getAppSetting('business_hours');
    window.businessHoursConfig = saved || DEFAULT_BIZ_HOURS;
    return window.businessHoursConfig;
  };

  window.calculateBusinessHours = function(startDate, endDate, config) {
    const cfg = config || window.businessHoursConfig || DEFAULT_BIZ_HOURS;
    const tz = cfg.timezone || 'America/New_York';
    const openH = cfg.openHour ?? 9;
    const openM = cfg.openMinute ?? 0;
    const closeH = cfg.closeHour ?? 18;
    const closeM = cfg.closeMinute ?? 0;
    const workDays = cfg.workDays || [1, 2, 3, 4, 5];

    const start = new Date(startDate);
    const end = new Date(endDate);
    if (start >= end) return 0;

    function toTZ(d) {
      return new Date(d.toLocaleString('en-US', { timeZone: tz }));
    }

    const startTZ = toTZ(start);
    const endTZ = toTZ(end);

    let totalMinutes = 0;

    let day = new Date(startTZ);
    day.setHours(0, 0, 0, 0);

    const lastDay = new Date(endTZ);
    lastDay.setHours(0, 0, 0, 0);

    while (day <= lastDay) {
      if (workDays.includes(day.getDay())) {
        const bizOpen = new Date(day);
        bizOpen.setHours(openH, openM, 0, 0);

        const bizClose = new Date(day);
        bizClose.setHours(closeH, closeM, 0, 0);

        const rangeStart = startTZ > bizOpen ? startTZ : bizOpen;
        const rangeEnd = endTZ < bizClose ? endTZ : bizClose;

        if (rangeStart < rangeEnd) {
          totalMinutes += (rangeEnd - rangeStart) / (1000 * 60);
        }
      }

      day.setDate(day.getDate() + 1);
    }

    return Math.round(totalMinutes / 60 * 10) / 10;
  };

  console.log('Supabase connected to Avemar Production Tracking');
})();
