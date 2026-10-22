'use strict';
'require view';
'require form';
'require rpc';
'require uci';
'require ui';
'require poll';

var callStatus = rpc.declare({ object: 'luci.torrserver', method: 'status', expect: { '': {} } });
var callLog = rpc.declare({ object: 'luci.torrserver', method: 'log', expect: { '': {} } });
var callAction = rpc.declare({
	object: 'luci', method: 'setInitAction', params: [ 'name', 'action' ], expect: { result: false }
});

return view.extend({
	load: function() {
		return uci.load('torrserver');
	},

	render: function() {
		var status = E('p', {}, _('Loading service status…'));
		var metrics = E('p');
		var web = E('a', { 'class': 'cbi-button', target: '_blank', rel: 'noopener noreferrer' }, _('Open TorrServer'));
		var log = E('pre', { style: 'max-height:24rem;overflow:auto;white-space:pre-wrap' });
		var logVisible = false;
		var busy = false;
		var buttons = [];
		var refresh = function() {
			return callStatus().then(function(reply) {
				if (!reply.service || !reply.web || !reply.proc || !reply.ram)
					throw new Error(_('Incomplete status response'));
				status.textContent = (reply.service.running ? _('Running') : _('Stopped')) +
					(reply.service.pid ? ' · PID ' + reply.service.pid : '') +
					' · ' + _('Version') + ': ' + (reply.version || '—');
				metrics.textContent = 'CPU: ' + (reply.proc.cpu_pct || '0.0') + '% · RAM: ' + ((reply.proc.rss_kb || 0) / 1024).toFixed(1) + ' MiB · ' +
					_('Available system memory') + ': ' + ((reply.ram.avail_kb || 0) / 1024).toFixed(0) + ' MiB';
				var host = window.location.hostname;
				if (host.indexOf(':') >= 0 && host.charAt(0) !== '[')
					host = '[' + host + ']';
				web.href = 'http://' + host + ':' + reply.web.port + '/';
				buttons.forEach(function(button) { button.disabled = busy; });
			}).catch(function(error) {
				status.textContent = _('Status unavailable') + ': ' + error.message;
			});
		};
		var controls = E('div', { 'class': 'cbi-section' }, [ status, metrics, web ]);
		[ [ 'start', _('Start') ], [ 'stop', _('Stop') ], [ 'restart', _('Restart') ] ].forEach(function(entry) {
			var button = E('button', {
				'class': 'cbi-button cbi-button-action', style: 'margin:0 .3rem',
				type: 'button', click: function() {
					busy = true;
					buttons.forEach(function(control) { control.disabled = true; });
					status.textContent = _('Applying service action…');
					return callAction('torrserver', entry[0]).then(function(ok) {
						if (!ok)
							throw new Error(_('Service action failed'));
					}).catch(function(error) {
						ui.addNotification(null, E('p', {}, error.message), 'error');
					}).finally(function() { busy = false; return refresh(); });
				}
			}, entry[1]);
			buttons.push(button);
			controls.appendChild(button);
		});
		controls.appendChild(E('button', {
			'class': 'cbi-button', type: 'button', click: function() {
				logVisible = !logVisible;
				log.hidden = !logVisible;
				return logVisible ? callLog().then(function(reply) {
					log.textContent = (reply.lines || []).join('\n') || _('No log entries');
				}).catch(function(error) { log.textContent = error.message; }) : null;
			}
		}, _('Show / hide log')));
		log.hidden = true;
		controls.appendChild(log);

		var map = new form.Map('torrserver', 'TorrServer',
			_('Torrent streaming server. Settings are applied only after Save & Apply. Streaming and torrent management are available in the TorrServer web interface.'));
		var section = map.section(form.NamedSection, 'main', 'torrserver');
		section.addremove = false;
		section.tab('general', _('General'));
		section.tab('auth', _('Authentication'));
		section.tab('proxy', _('Proxy'));
		section.tab('advanced', _('Advanced'));
		var option = section.taboption('general', form.Flag, 'enabled', _('Enable service'),
			_('Allow startup at boot and after applying settings. Disable this option to keep the service stopped.'));
		option.default = '1';
		option.rmempty = false;
		option = section.taboption('general', form.Value, 'port', _('HTTP port'));
		option.datatype = 'port';
		option.default = '8090';
		option.rmempty = false;
		option = section.taboption('general', form.Value, 'ip', _('Bind address'),
			_('Empty listens on all interfaces. Use a local router address to restrict the listener. No firewall ports are opened by this package.'));
		option.datatype = 'ipaddr';
		option = section.taboption('general', form.Value, 'path', _('Data directory'),
			_('Database and settings directory. Keep the existing path when upgrading. Cache settings are managed in TorrServer itself.'));
		option.default = '/opt/torrserver';
		option.rmempty = false;
		option.validate = function(sectionId, value) {
			return value && value.charAt(0) === '/' ? true : _('Use an absolute path');
		};
		option = section.taboption('auth', form.Flag, 'httpauth', _('Require HTTP authentication'));
		option.rmempty = false;
		option = section.taboption('auth', form.Value, 'auth_user', _('Username'));
		option.depends('httpauth', '1');
		option.default = 'torrserver';
		option.rmempty = false;
		option = section.taboption('auth', form.Value, 'auth_password', _('Password'),
			_('Credentials are stored locally in the root-only UCI configuration and accs.db. Set both fields when enabling authentication.'));
		option.password = true;
		option.depends('httpauth', '1');
		option.rmempty = false;
		option = section.taboption('proxy', form.Value, 'proxyurl', _('Proxy URL'),
			_('Optional HTTP or SOCKS proxy for TorrServer. Transparent VPN routing is configured separately in your router software.'));
		option.placeholder = 'socks5://127.0.0.1:1080';
		option = section.taboption('proxy', form.ListValue, 'proxymode', _('Proxy mode'));
		option.value('tracker', _('HTTP trackers'));
		option.value('peers', _('Peer connections'));
		option.value('full', _('All supported traffic'));
		option.default = 'tracker';
		[ [ 'rdb', _('Read-only database') ], [ 'webdav', _('Enable WebDAV') ] ].forEach(function(entry) {
			section.taboption('advanced', form.Flag, entry[0], entry[1]);
		});
		[
			[ 'logpath', _('Log file'), _('Empty uses the system log. Avoid unlimited logs on internal flash.') ],
			[ 'weblogpath', _('Web log file') ],
			[ 'torrentsdir', _('Torrent autoload directory') ],
			[ 'torrentaddr', _('Torrent listen address'), _('For example :6881 or 192.168.1.1:6881.') ],
			[ 'pubipv4', _('Announced IPv4 address') ],
			[ 'pubipv6', _('Announced IPv6 address') ],
			[ 'maxsize', _('Maximum stream size in bytes'), _('Limits the stream size, not the RAM cache. Empty leaves the upstream default.') ],
			[ 'tg', _('Telegram bot token') ],
			[ 'fuse', _('FUSE mount directory'), _('Requires working FUSE support and a mounted destination on the router.') ]
		].forEach(function(entry) {
			var field = section.taboption('advanced', form.Value, entry[0], entry[1], entry[2]);
			if (entry[0] === 'maxsize') field.datatype = 'uinteger';
			if (entry[0] === 'pubipv4') field.datatype = 'ip4addr';
			if (entry[0] === 'pubipv6') field.datatype = 'ip6addr';
			if (entry[0] === 'tg') field.password = true;
		});
		poll.add(refresh, 5);
		return map.render().then(function(node) {
			return refresh().then(function() { return E('div', {}, [ controls, node ]); });
		});
	}
});
