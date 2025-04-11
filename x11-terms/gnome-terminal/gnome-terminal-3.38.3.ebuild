# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit autotools gnome2 readme.gentoo-r1

DESCRIPTION="A terminal emulator for GNOME"
HOMEPAGE="https://wiki.gnome.org/Apps/Terminal/ https://gitlab.gnome.org/GNOME/gnome-terminal"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="*"

IUSE="debug +deprecated-transparency +gnome-shell +nautilus vanilla-hotkeys +vanilla-icon vanilla-notify vanilla-open-terminal"

# FIXME: automagic dependency on gtk+[X], just transitive but needs proper control, bug 624960
RDEPEND="
	>=dev-libs/glib-2.52:2
	>=x11-libs/gtk+-3.22.27:3
	>=x11-libs/vte-0.62.3:2.91[!vanilla-notify?]
	>=dev-libs/libpcre2-10
	>=gnome-base/dconf-0.14
	>=gnome-base/gsettings-desktop-schemas-0.1.0
	sys-apps/util-linux
	gnome-shell? ( gnome-base/gnome-shell )
	nautilus? ( >=gnome-base/nautilus-3.28.0 )
"
DEPEND="${RDEPEND}"
# itstool required for help/* with non-en LINGUAS, see bug #549358
# xmllint required for glib-compile-resources, see bug #549304
BDEPEND="
	dev-libs/libxml2:2
	dev-libs/libxslt
	dev-util/gdbus-codegen
	dev-util/itstool
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
"

DOC_CONTENTS="To get previous working directory inherited in new opened tab, or
	notifications of long-running commands finishing, you will need
	to add the following line to your ~/.bashrc:\n
	. /etc/profile.d/vte-2.91.sh"

src_prepare() {
	if ! use vanilla-icon; then
		eapply "${FILESDIR}"/${PN}-3.32.1-desktop-icon.patch
	fi

	if use deprecated-transparency; then
		# From Fedora:
		# 	https://src.fedoraproject.org/rpms/gnome-terminal/tree/f33
		eapply "${FILESDIR}"/${PN}-3.28.1-build-dont-treat-warnings-as-errors.patch
		eapply "${FILESDIR}"/${PN}-3.38.3-transparency.patch

		# From GNOME:
		# 	https://gitlab.gnome.org/GNOME/gnome-terminal/-/commit/b3c270b3612acd45f309521cf1167e1abd561c09
		eapply "${FILESDIR}"/${PN}-3.14.3-fix-broken-transparency-on-startup.patch

		if ! use vanilla-notify; then
			# From Fedora:
			# 	https://src.fedoraproject.org/rpms/gnome-terminal/tree/f33
			eapply "${FILESDIR}"/${PN}-3.38.3-open-notify-title-rebased.patch
		fi
	elif ! use vanilla-notify; then
		# From Fedora:
		# 	https://src.fedoraproject.org/rpms/gnome-terminal/tree/f33
		eapply "${FILESDIR}"/${PN}-3.38.3-open-notify-title.patch
	fi

	if ! use vanilla-hotkeys; then
		# From Funtoo:
		# 	https://bugs.funtoo.org/browse/FL-1652
		eapply "${FILESDIR}"/${PN}-3.28.1-disable-function-keys.patch
	fi

	eautoreconf
	gnome2_src_prepare
}

src_configure() {
	gnome2_src_configure \
		--disable-static \
		$(use_enable debug) \
		$(use_enable gnome-shell search-provider) \
		$(use_with nautilus nautilus-extension)
}

src_install() {
	gnome2_src_install
	if ! use vanilla-open-terminal; then
		# Separate "New Window/Tab" menu entries by default, instead of unified "New Terminal"
		insinto /usr/share/glib-2.0/schemas
		newins "${FILESDIR}"/separate-new-tab-window.gschema.override org.gnome.Terminal.gschema.override
	fi
	readme.gentoo_create_doc
}

pkg_postinst() {
	gnome2_pkg_postinst
	readme.gentoo_print_elog
}
