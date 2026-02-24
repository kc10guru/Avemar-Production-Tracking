-- Migration: Add document upload support
-- Run this in Supabase SQL Editor to add document upload capability

-- 1. Create the repair_order_documents table
CREATE TABLE IF NOT EXISTS repair_order_documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  repair_order_id UUID NOT NULL REFERENCES repair_orders(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_type TEXT,
  file_size BIGINT,
  stage_number INTEGER,
  uploaded_by UUID,
  uploaded_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_ro_documents_repair_order ON repair_order_documents(repair_order_id);

-- 2. Enable RLS and add policies
ALTER TABLE repair_order_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read repair_order_documents" ON repair_order_documents FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert repair_order_documents" ON repair_order_documents FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update repair_order_documents" ON repair_order_documents FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete repair_order_documents" ON repair_order_documents FOR DELETE TO authenticated USING (true);

-- 3. Create storage bucket for repair order documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('repair-order-docs', 'repair-order-docs', false)
ON CONFLICT (id) DO NOTHING;

-- 4. Storage policies
CREATE POLICY "Authenticated users can upload repair docs" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'repair-order-docs');
CREATE POLICY "Authenticated users can read repair docs" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'repair-order-docs');
CREATE POLICY "Authenticated users can delete repair docs" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'repair-order-docs');
