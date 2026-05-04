create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  payment_code text not null,
  gcash_transaction_id text,
  amount integer not null default 9900,
  status text not null default 'pending',
  created_at timestamptz default now()
);

alter table payments enable row level security;

create policy "Users can insert own payments" on payments
  for insert with check (auth.uid() = user_id);

create policy "Users can view own payments" on payments
  for select using (auth.uid() = user_id);

create policy "Admin can view all payments" on payments
  for select using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create policy "Admin can update all payments" on payments
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );
