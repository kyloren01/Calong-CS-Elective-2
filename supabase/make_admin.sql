-- Every new account starts as a customer. To make one an admin:
--   1. Sign up in the app with that email first.
--   2. Put the same email below.
--   3. Run this in Supabase -> SQL Editor, then sign out and in again.

update public.profiles
set role_id = (select id from public.roles where role = 'admin')
where email = 'kicksoccillada+admin@gmail.com';

-- Check the result: the account should show "admin".
select p.email, p.firstname, p.lastname, r.role
from public.profiles p
join public.roles r on r.id = p.role_id
order by r.role, p.email;
