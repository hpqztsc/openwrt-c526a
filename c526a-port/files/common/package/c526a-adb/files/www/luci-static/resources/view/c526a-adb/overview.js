'use strict';
'require view';

return view.extend({
	render: function() {
		var host = window.location.hostname;
		if (host.indexOf(':') !== -1)
			host = '[' + host + ']';
		var termURL = 'http://' + host + ':7682/';

		return E('div', { 'class': 'cbi-map' }, [
			E('h2', {}, _('ADB 控制台')),
			E('div', { 'class': 'cbi-map-descr' }, [
				_('ADB 控制台是独立页面，包含短信/MMS、联系人、通话记录、通知、文件浏览、'),
				_('系统信息、应用列表、截屏录屏、输入控制和交互式终端。'),
				E('br'),
				_('多设备时在页面顶部选择目标设备，选择会记忆在当前浏览器。'),
				E('br'),
				_('API Token 在 /root/adb-token；终端密码在 /root/adb-term-password。')
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('p', {}, [
					E('a', {
						'href': '/adb/',
						'target': '_blank',
						'rel': 'noopener',
						'class': 'btn cbi-button cbi-button-apply'
					}, _('打开 ADB 控制台'))
				]),
				E('p', {}, [
					E('a', {
						'href': termURL,
						'target': '_blank',
						'rel': 'noopener',
						'class': 'btn cbi-button cbi-button-action'
					}, _('打开 ADB 交互终端'))
				])
			])
		]);
	}
});
