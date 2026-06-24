const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function check() {
  const { data: profiles, error: pErr } = await supabase.from('profiles').select('*').limit(1);
  console.log('Profiles:', profiles, pErr ? pErr.message : '');

  const { data: users, error: uErr } = await supabase.from('users').select('*').limit(1);
  console.log('Users:', users, uErr ? uErr.message : '');
}
check();
