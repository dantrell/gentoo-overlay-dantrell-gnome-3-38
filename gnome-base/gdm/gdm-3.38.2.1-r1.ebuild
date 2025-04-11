# Distributed under the terms of the GNU General Public License v2

EAPI="8"

inherit desktop gnome2 meson pam readme.gentoo-r1 systemd udev

DESCRIPTION="GNOME Display Manager for managing graphical display servers and user logins"
HOMEPAGE="https://wiki.gnome.org/Projects/GDM https://gitlab.gnome.org/GNOME/gdm"

SRC_URI="${SRC_URI}
	branding? ( https://www.mail-archive.com/tango-artists@lists.freedesktop.org/msg00043/tango-gentoo-v1.1.tar.gz )
"

LICENSE="
	GPL-2+
	branding? ( CC-BY-SA-4.0 )
"
SLOT="0"
KEYWORDS="*"

IUSE="accessibility audit bluetooth-sound branding elogind fprint plymouth selinux systemd tcpd test wayland"
REQUIRED_USE="?? ( elogind systemd )"

RESTRICT="!test? ( test )"

# dconf, dbus and g-s-d are needed at install time for dconf update
# keyutils is automagic dep that makes autologin unlock login keyring when all the passwords match (disk encryption, user pw and login keyring)
# dbus-run-session used at runtime
COMMON_DEPEND="
	virtual/udev
	>=dev-libs/libgudev-232:=
	>=dev-libs/glib-2.56:2
	>=x11-libs/gtk+-2.91.1:3
	>=media-libs/libcanberra-0.4[gtk3]
	>=sys-apps/accountsservice-0.6.35
	x11-libs/libxcb
	sys-apps/keyutils:=
	selinux? ( sys-libs/libselinux )

	x11-libs/libX11
	x11-libs/libXau
	x11-base/xorg-server[-minimal]
	x11-libs/libXdmcp
	tcpd? ( >=sys-apps/tcp-wrappers-7.6 )

	systemd? ( >=sys-apps/systemd-186:0=[pam] )
	elogind? ( >=sys-auth/elogind-239.3[pam] )

	plymouth? ( sys-boot/plymouth )
	audit? ( sys-process/audit )

	>=sys-libs/pam-1.5.0
	>=sys-auth/pambase-20200721[elogind?,systemd?]

	>=gnome-base/dconf-0.20
	>=gnome-base/gnome-settings-daemon-3.1.4
	gnome-base/gsettings-desktop-schemas
	sys-apps/dbus

	>=x11-misc/xdg-utils-1.0.2-r3

	>=dev-libs/gobject-introspection-0.9.12:=
"
# XXX: These deps are from session and desktop files in data/ directory
# fprintd is used via dbus by gdm-fingerprint-extension
RDEPEND="${COMMON_DEPEND}
	acct-group/gdm
	acct-user/gdm
	>=gnome-base/gnome-session-3.6
	>=gnome-base/gnome-shell-3.1.90
	x11-apps/xhost

	accessibility? (
		>=app-accessibility/orca-3.10
		gnome-extra/mousetweaks
	)
	fprint? ( sys-auth/fprintd[pam] )
"
DEPEND="${COMMON_DEPEND}
	x11-base/xorg-proto
"
BDEPEND="
	app-text/docbook-xml-dtd:4.1.2
	dev-util/gdbus-codegen
	dev-util/itstool
	>=gnome-base/dconf-0.20
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
	test? ( >=dev-libs/check-0.9.4 )
	app-text/yelp-tools
"

DOC_CONTENTS="
	To make GDM start at boot with systemd, run:\n
	# systemctl enable gdm.service\n
	\n
	To make GDM start at boot with OpenRC, edit /etc/conf.d to have
	DISPLAYMANAGER=\"gdm\" and enable the xdm service:\n
	# rc-update add xdm
	\n
	For passwordless login to unlock your keyring, you need to install
	sys-auth/pambase with USE=gnome-keyring and set an empty password
	on your keyring. Use app-crypt/seahorse for that.\n
	\n
	You may need to install app-crypt/coolkey and sys-auth/pam_pkcs11
	for smartcard support
"

PATCHES=(
	# Add elogind support
	"${FILESDIR}"/${PN}-40.0-meson-allow-building-with-elogind.patch
)

src_prepare() {
	default

	if ! use wayland; then
		eapply "${FILESDIR}"/${PN}-3.30.0-prioritize-xorg.patch
	else
		# From GNOME:
		# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/5cd78602d3d4c8355869151875fc317e8bcd5f08
		eapply "${FILESDIR}"/${PN}-3.36.3-data-disable-wayland-for-proprietary-nvidia-machines.patch
	fi

	# From GNOME (plug fd leaks):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/fa310e53ca7ab885405a832d2213c899314ec18e
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/a4de923d3a666e1c30b9e268dab750b7ec1c5d5d
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/97ca4b1268e78a21041d9fda9512b892ce344d92
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/5b4844aeeb2430a5e9b20ef4148cecd13b418357
	eapply "${FILESDIR}"/${PN}-40_beta-manager-dont-leak-session-objects.patch
	eapply "${FILESDIR}"/${PN}-40_beta-manager-clean-up-user-session-when-finished-with-display.patch
	eapply "${FILESDIR}"/${PN}-40_beta-session-dont-leak-remote-greeter-interface.patch
	eapply "${FILESDIR}"/${PN}-40_beta-xdmcp-display-factory-clear-launch-environment-when-done-with-it.patch

	# From GNOME (plug proxy leaks):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/46c30254806a53cfc9d5a342eb7486cdf6475186
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/1222ffdce0f175e32eb2d5cdd4c1f36232547442
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/2615fb4ffe05b2640c15f4a9706796fe3b1376a9
	eapply "${FILESDIR}"/${PN}-40_beta-libgdm-fix-client-leaks-from-g-async-result-get-source-object.patch
	eapply "${FILESDIR}"/${PN}-40_beta-libgdm-fetch-connection-synchronously.patch
	eapply "${FILESDIR}"/${PN}-40_beta-libgdm-dont-leak-user-verifier-extensions-on-unlock.patch

	# From GNOME (handle existing users errors):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/4e6e5335d29c039bed820c43bfd1c19cb62539ff
	eapply "${FILESDIR}"/${PN}-40_beta-display-use-autoptr-to-handle-errors-in-look-for-existing-users.patch

	# From GNOME (GDM client fixes):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/724381820fe83be7f6f54299278566ac6dcf915b
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/2593ee760b5eb78590d8f8956635ec12b8b250bd
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/c37740ba72bbe4be5304cef3306b8a3eb4976ec3
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/eae6dc60ec79be63b85f6eeae4238c99acae3956
	eapply "${FILESDIR}"/${PN}-40_beta-libgdm-fix-typo-where-user-data-is-grabbed-from-wrong-place.patch
	eapply "${FILESDIR}"/${PN}-40_beta-libgdm-use-g-set-weak-pointer-instead-of-g-object-add-weak-pointer.patch
	eapply "${FILESDIR}"/${PN}-40_beta-libgdm-track-reauth-user-verifier-too.patch
	eapply "${FILESDIR}"/${PN}-40_beta-meson-bump-glib-version-requirement.patch

	# From GNOME (handle PAM max retries):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/39bf1df0620f4942a843f747474d78f13d9983ea
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/e2f3b1a56a3c2041c22fad3e82086c8a31988a9a
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/40bf4d3e0bb94a4953f16daad8ce307f82231b75
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/504fec05f9ce504473935f2ae3a5bc22cc49a185
	eapply "${FILESDIR}"/${PN}-40_beta-session-worker-use-a-clearer-message-on-max-retries-error.patch
	eapply "${FILESDIR}"/${PN}-40_beta-session-worker-mention-the-authentication-method-if-known-on-error-messages.patch
	eapply "${FILESDIR}"/${PN}-40_beta-session-worker-remove-stray-comma.patch
	eapply "${FILESDIR}"/${PN}-40_beta-session-threat-pam-max-retries-error-as-service-unavailable.patch

	# From GNOME (import PATH):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/ccecd9c975d04da80db4cd547b67a1a94fa83292
	eapply "${FILESDIR}"/${PN}-40_beta-gdm-wayland-x-session-dont-overwrite-user-env-with-fallback-vars.patch

	# From GNOME (wait for any DRM device before starting GDM):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/de7df6f24aee51fe89bab096f784e22578a83cbb
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/05febece290145c24f5d569f1895f41328294594
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/d2a06b42fe90cf3f340ebf41a0a5e7676bc50802
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/a37e5a950fbd737f6630eff7853456d013fd57c9
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/36c040fd8daccafc3105407d7fa4ef7bc3d2d73c
	eapply "${FILESDIR}"/${PN}-40_beta-daemon-common-libgdm-drop-use-of-sd-seat-can-multi-session.patch
	eapply "${FILESDIR}"/${PN}-40_beta-local-display-factory-rename-create-display-to-show-it-is-idempotent.patch
	eapply "${FILESDIR}"/${PN}-40_beta-local-display-factory-move-session-type-checking-into-create-display.patch
	eapply "${FILESDIR}"/${PN}-40_beta-local-display-factory-wait-for-seats-to-become-graphical.patch
	eapply "${FILESDIR}"/${PN}-40_rc-local-display-factory-fix-wait-for-graphical.patch

	# From GNOME (fix conversation error reporting):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/527186cef3d87c641e0f767a59a6f23d24118e72
	eapply "${FILESDIR}"/${PN}-40_rc-session-initialize-dbus-error-domain-before-resolving-errors.patch

	# From GNOME (fix infinite loop):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/a63ec01de0cc054d0ab83200a481bbc04e04d738
	eapply "${FILESDIR}"/${PN}-40.0-display-factory-correctly-return-from-idle-callback.patch

	# From GNOME (handle PAM cached passwords):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/f365ba1d55c186e2aa93ecf2c897af24d872e767
	eapply "${FILESDIR}"/${PN}-41_alpha-pam-gdm-use-the-last-cryptsetup-password-instead-of-the-first.patch

	# From GNOME (fix emitting verification-complete signal):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/f65c681a469a2675d96012a77a563e50369b9e54
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/2f9afacd494311b8b7393848fec59bc8df7520b7
	eapply "${FILESDIR}"/${PN}-41_alpha-session-only-emit-verification-complete-on-reauth-or-after-session-is-opened.patch
	eapply "${FILESDIR}"/${PN}-41_alpha-session-emit-session-opened-failed-on-session-failures.patch

	# From GNOME (fix libwrap detection):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/a98087f2711c7211871215b1ddef0383e14a3dc4
	eapply "${FILESDIR}"/${PN}-41_alpha-meson-fix-libwrap-detection.patch

	# From GNOME (handle display registration):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/2e7636d431fff0b3a808184c086a60e2c136c1a1
	eapply "${FILESDIR}"/${PN}-41_alpha-display-handle-failure-before-display-registration.patch

	# From GNOME (wait for main DRM device before starting GDM):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/04853a3b8c17712cc7f74c3c405ef47af53151c1
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/ae81d9bdd1e378598cf805c84af4313f8e10b3ed
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/2a871da666afd3a5312e061b7933e7b62eb5ee39
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/495b4fc0d7c65f76b03108199085df4fca98618c
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/f4922c046607c45d76e2911aa8f133d0ad4f9223
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/bf9ecc62100032ede9d981529ff5943c07315509
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/887e462fbc4840bf9b97f101f15c6015b461f11f
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/4a7ef1e94fbfaf4ed2506183b3ef35f2ff458a62
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/b1367915672ea51c99b21ac764a8452d0529a5ea
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/d17fdb8521576f90191c077806b7f470f6a37be0
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/eba8deb7f92f473a40a8e277203d86aeab879bd1
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/2e22ac85d52b2fe68949f7af4e27331e6714309c
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/895f765aa8cc5a9dd2901be65bcd638b8aa7c577
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/c4f81c020aa08458cbad8b21509913a48c91926a
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/45daec660b6288748f4bec6410765829eed926c2
	eapply "${FILESDIR}"/${PN}-41_alpha-daemon-provide-more-flexibility-for-configuring-display-server.patch
	eapply "${FILESDIR}"/${PN}-41_alpha-libgdm-sort-session-list.patch
	eapply "${FILESDIR}"/${PN}-41_alpha-worker-dont-load-user-settings-for-program-sessions.patch
	eapply "${FILESDIR}"/${PN}-41_alpha-session-support-new-accountsservice-session-and-sessiontype-props.patch
	eapply "${FILESDIR}"/${PN}-41_alpha-local-display-factory-fix-overrun-in-session-type-list-generation.patch
	eapply "${FILESDIR}"/${PN}-41_alpha-local-display-factory-add-missing-continue-statements.patch
	eapply "${FILESDIR}"/${PN}-41_alpha-session-fix-operators-when-computing-session-dirs.patch
	eapply "${FILESDIR}"/${PN}-41_alpha-manager-plumb-supported-session-types-down-to-the-session.patch
	eapply "${FILESDIR}"/${PN}-41_alpha-session-fix-gdm-session-is-wayland-session.patch
	eapply "${FILESDIR}"/${PN}-41.0-daemon-dont-update-session-type-if-no-saved-session.patch
	eapply "${FILESDIR}"/${PN}-41.0-daemon-consolidate-session-type-and-supported-session-types-list.patch
	eapply "${FILESDIR}"/${PN}-41.3-local-display-factory-dont-try-to-respawn-displays-on-shutdown.patch
	eapply "${FILESDIR}"/${PN}-42.0-local-display-factory-stall-startup-until-main-graphics-card-is-ready.patch
	eapply "${FILESDIR}"/${PN}-42.0-common-add-api-to-reload-settings-from-disk.patch
	eapply "${FILESDIR}"/${PN}-42.0-common-reload-settings-when-graphics-initialize.patch

	# From GNOME (fix VT switching):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/304d25de77d89740f12b31f251ac771a54f8dc55
	eapply "${FILESDIR}"/${PN}-41_rc-session-worker-set-session-vt-0-out-of-pam-uninitialization.patch

	# From GNOME (update PAM files):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/bd1594deb1ab99378e8a488a5ecbb515ba215ab9
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/be8d893ab1ad78e7e72068145c5481f82462267e
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/7661ffceaa8e0e19d129d5376546438af56f7750
	eapply "${FILESDIR}"/${PN}-41.3-pam-drop-gdm-pin-service.patch
	eapply "${FILESDIR}"/${PN}-42.0-pam-exherbo-update-to-reflect-pam-changes.patch
	eapply "${FILESDIR}"/${PN}-42.0-pam-exherbo-update-gdm-launch-environment.patch

	# From GNOME (stop listening for events after UDEV is settled):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/f0f527ff3815caa091be24168824f74853c0c050
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/307c683f00e1711973139837992ca0f6f55314a5
	eapply "${FILESDIR}"/${PN}-43.0-local-display-factory-fix-type-of-signal-connection-id.patch
	eapply "${FILESDIR}"/${PN}-43.0-local-display-factory-stop-listening-to-udev-events-when-necessary.patch

	# From GNOME (cache remote users):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/cf4664891ede9648d096569900e8b95abd91a633
	eapply "${FILESDIR}"/${PN}-43.0-session-settings-explicitly-cache-remote-users.patch

	# From GNOME (fix supported session types):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/6247ca134fb84a609915dfc627c8b3330a681cb5
	eapply "${FILESDIR}"/${PN}-43.0-local-display-factory-fix-typo-in-supported-session-types.patch

	# From GNOME (plug memory leaks):
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/a95d9169a1ce0f0c280da4152269551651ea902b
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/8edb5c4aef9bfa3a1d12a496c289644d330d3407
	# 	https://gitlab.gnome.org/GNOME/gdm/-/commit/75ac44ec86af05bf01be3420cc733c3dfcb5cd18
	eapply "${FILESDIR}"/${PN}-43.1-gdm-display-plug-a-memory-leak.patch
	eapply "${FILESDIR}"/${PN}-43.1-gdm-session-worker-plug-a-memory-leak.patch
	eapply "${FILESDIR}"/${PN}-43.1-gdm-local-display-factory-plug-a-memory-leak.patch

	# Show logo when branding is enabled
	use branding && eapply "${FILESDIR}"/${PN}-3.30.3-logo.patch
}

src_configure() {
	# PAM is the only auth scheme supported
	# even though configure lists shadow and crypt
	# they don't have any corresponding code.
	local emesonargs=(
		--localstatedir /var

		-Ddefault-pam-config=exherbo
		-Dgdm-xsession=true
		-Dgroup=gdm
		-Dipv6=true
		$(meson_feature audit libaudit)
		-Dlogind-provider=$(usex systemd systemd elogind)
		-Dpam-mod-dir=$(getpam_mod_dir)
		$(meson_feature plymouth)
		-Drun-dir=/run/gdm
		$(meson_feature selinux)
		$(meson_use systemd systemd-journal)
		$(meson_use tcpd tcp-wrappers)
		-Dudev-dir=$(get_udevdir)/rules.d
		-Duser=gdm
		-Duser-display-server=true
		$(meson_use wayland wayland-support)
		-Dxdmcp=enabled
	)

	if use systemd; then
		emesonargs+=(
			-Dinitial-vt=1
			-Dsystemdsystemunitdir="$(systemd_get_systemunitdir)"
			-Dsystemduserunitdir="$(systemd_get_userunitdir)"
		)
	else
		emesonargs+=(
			-Dinitial-vt=7
			-Dsystemdsystemunitdir=no
			-Dsystemduserunitdir=no
		)
	fi

	meson_src_configure
}

src_install() {
	meson_src_install

	if ! use accessibility ; then
		rm "${ED}"/usr/share/gdm/greeter/autostart/orca-autostart.desktop || die
	fi

	if ! use bluetooth-sound ; then
		# Workaround https://gitlab.freedesktop.org/pulseaudio/pulseaudio/merge_requests/10
		# bug #679526
		insinto /var/lib/gdm/.config/pulse
		doins "${FILESDIR}"/default.pa
	fi

	# install XDG_DATA_DIRS gdm changes
	echo 'XDG_DATA_DIRS="/usr/share/gdm"' > 99xdg-gdm
	doenvd 99xdg-gdm

	use branding && newicon "${WORKDIR}/tango-gentoo-v1.1/scalable/gentoo.svg" gentoo-gdm.svg

	readme.gentoo_create_doc
}

pkg_postinst() {
	gnome2_pkg_postinst
	local d ret

	# bug #669146; gdm may crash if /var/lib/gdm subdirs are not owned by gdm:gdm
	ret=0
	ebegin "Fixing ${EROOT}/var/lib/gdm ownership"
	chown --no-dereference gdm:gdm "${EROOT}/var/lib/gdm" || ret=1
	for d in "${EROOT}/var/lib/gdm/"{.cache,.color,.config,.dbus,.local}; do
		[[ ! -e "${d}" ]] || chown --no-dereference -R gdm:gdm "${d}" || ret=1
	done
	eend ${ret}

	systemd_reenable gdm.service
	readme.gentoo_print_elog

	udev_reload
}

pkg_postrm() {
	udev_reload
}
