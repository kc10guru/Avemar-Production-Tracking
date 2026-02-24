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

  // Generate RO number: RO-YYYYMMDD-XXXX
  function generateRoNumber() {
    const now = new Date();
    const datePart = now.toISOString().slice(0, 10).replace(/-/g, '');
    const rand = Math.floor(1000 + Math.random() * 9000);
    return `RO-${datePart}-${rand}`;
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
      if (!snakeData.ro_number) snakeData.ro_number = generateRoNumber();
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

    // ─── Dashboard Helpers ──────────────────────────────────
    async getDashboardStats() {
      const [orders, stages, lowStock] = await Promise.all([
        this.getRepairOrders(),
        this.getProductionStages(),
        this.getLowStockSubcomponents()
      ]);

      const active = orders.filter(o => o.status === 'In Progress');
      const completed = orders.filter(o => o.status === 'Completed');
      const onHold = orders.filter(o => o.status === 'On Hold');

      const now = new Date();
      const thisMonth = completed.filter(o => {
        const d = new Date(o.dateCompleted);
        return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
      });

      // Count units per stage and detect late items
      const stageMap = stages.map(stage => {
        const unitsInStage = active.filter(o => o.currentStage === stage.stageNumber);
        const lateUnits = unitsInStage.filter(o => {
          const history = null; // will need to be enriched
          return false;
        });
        return {
          ...stage,
          unitCount: unitsInStage.length,
          lateCount: 0,
          units: unitsInStage
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

  console.log('Supabase connected to Avemar Production Tracking');
})();
