--[[
Copyright (c) 2016, Andrew Lewis <nerf@judo.za.org>
Copyright (c) 2017, Vsevolod Stakhov <vsevolod@highsecure.ru>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]--

local rspamd_util = require "rspamd_util"
local lua_util = require "lua_util"

local default_settings = {
  spf_symbols = {
    pass = 'R_SPF_ALLOW',
    fail = 'R_SPF_FAIL',
    softfail = 'R_SPF_SOFTFAIL',
    neutral = 'R_SPF_NEUTRAL',
    temperror = 'R_SPF_DNSFAIL',
    none = 'R_SPF_NA',
    permerror = 'R_SPF_PERMFAIL',
  },
  dmarc_symbols = {
    pass = 'DMARC_POLICY_ALLOW',
    permerror = 'DMARC_BAD_POLICY',
    temperror = 'DMARC_DNSFAIL',
    none = 'DMARC_NA',
    reject = 'DMARC_POLICY_REJECT',
    softfail = 'DMARC_POLICY_SOFTFAIL',
    quarantine = 'DMARC_POLICY_QUARANTINE',
  },
  arc_symbols = {
    pass = 'ARC_ALLOW',
    permerror = 'ARC_INVALID',
    temperror = 'ARC_DNSFAIL',
    none = 'ARC_NA',
    reject = 'ARC_REJECT',
  },
  dkim_symbols = {
    none = 'R_DKIM_NA',
  },
  add_smtp_user = true,
}

local exports = {
  default_settings = default_settings
}

local local_hostname = rspamd_util.get_hostname()

function Split(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match);
  end
  return result;
end

local function gen_auth_results(task, settings)

  local hdr_parts = {}, {}
  local smtp_from = task:get_from('smtp')
  local smtp_hdr = lua_util.maybe_smtp_quote_value(smtp_from[1]['addr'])
  local spoof_sender_hdr = Split(smtp_hdr, '@')[2]
  local mta_hostname = task:get_request_header('MTA-Name') or task:get_request_header('MTA-Tag')
  local sender
  local sender_type
  local smtp_from = task:get_from('smtp')

  if mta_hostname then
    mta_hostname = tostring(mta_hostname)
  else
    mta_hostname = local_hostname
  end

  if smtp_from and
      smtp_from[1] and
      smtp_from[1]['addr'] ~= '' and
      smtp_from[1]['addr'] ~= nil then
    sender = lua_util.maybe_smtp_quote_value(smtp_from[1]['addr'])
    sender_type = 'smtp.mailfrom'
  else
    local helo = task:get_helo()
    if helo then
      sender = lua_util.maybe_smtp_quote_value(helo)
      sender_type = 'smtp.helo'
    end
  end

  table.insert(hdr_parts, string.format('%s', spoof_sender_hdr))
  table.insert(hdr_parts, string.format('dkim=pass header.d=%s', spoof_sender_hdr))
  table.insert(hdr_parts, string.format('dmarc=pass action=none header.from=%s', spoof_sender_hdr))
  table.insert(hdr_parts, string.format('spf=pass (%s: domain of %s designates DYNAMIC_IP_ADDRESS as permitted sender) smtp.mailfrom=%s', spoof_sender_hdr, sender, sender))


  return table.concat(hdr_parts, '; ')

end

exports.gen_auth_results = gen_auth_results

return exports
