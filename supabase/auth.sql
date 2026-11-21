-- Sign-in activity: only signed-in users may add, edit, or delete products.
-- Run after schema.sql: Dashboard -> SQL Editor -> New query -> Run.
-- Anyone can still read products. Safe to run more than once.

drop policy if exists "Anyone can add products" on public.products;
drop policy if exists "Anyone can update products" on public.products;
drop policy if exists "Anyone can delete products" on public.products;

drop policy if exists "Signed-in users can add products" on public.products;
create policy "Signed-in users can add products"
  on public.products for insert
  to authenticated
  with check (true);

drop policy if exists "Signed-in users can update products" on public.products;
create policy "Signed-in users can update products"
  on public.products for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Signed-in users can delete products" on public.products;
create policy "Signed-in users can delete products"
  on public.products for delete
  to authenticated
  using (true);
