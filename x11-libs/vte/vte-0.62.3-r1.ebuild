# Distributed under the terms of the GNU General Public License v2

EAPI="7"
VALA_USE_DEPEND="vapigen"
VALA_MIN_API_VERSION="0.48"
VALA_MAX_API_VERSION="0.52"

inherit gnome.org meson vala xdg

DESCRIPTION="Library providing a virtual terminal emulator widget"
HOMEPAGE="https://wiki.gnome.org/Apps/Terminal/VTE"

LICENSE="LGPL-3+ GPL-3+"
SLOT="2.91"
KEYWORDS="*"

IUSE="+crypt debug gtk-doc +icu +introspection systemd +vala vanilla-notify"
REQUIRED_USE="vala? ( introspection )"

RDEPEND="
	>=x11-libs/gtk+-3.24.14:3[introspection?]
	>=dev-libs/fribidi-1.0.0
	>=dev-libs/glib-2.52:2
	crypt?  ( >=net-libs/gnutls-3.2.7:0= )
	icu? ( dev-libs/icu:= )
	>=x11-libs/pango-1.22.0
	>=dev-libs/libpcre2-10.21
	systemd? ( >=sys-apps/systemd-220:= )
	sys-libs/zlib
	introspection? ( >=dev-libs/gobject-introspection-1.56:= )
	x11-libs/pango[introspection?]
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-libs/libxml2:2
	gtk-doc? ( >=dev-util/gtk-doc-1.13
		app-text/docbook-xml-dtd:4.1.2 )
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig

	vala? ( $(vala_depend) )
"

src_prepare() {
	if ! use vanilla-notify; then
		# From Fedora:
		# 	https://src.fedoraproject.org/rpms/vte291/tree/f33
		eapply "${FILESDIR}"/${PN}-0.62.3-cntnr-precmd-preexec-scroll.patch
	fi

	# -Ddebugg option enables various debug support via VTE_DEBUG, but also ggdb3; strip the latter
	sed -e '/ggdb3/d' -i meson.build || die

	use vala && vala_src_prepare
	xdg_src_prepare
}

src_configure() {
	local emesonargs=(
		-Da11y=true
		$(meson_use debug debugg)
		$(meson_use gtk-doc docs)
		$(meson_use introspection gir)
		-Dfribidi=true # pulled in by pango anyhow
		$(meson_use crypt gnutls)
		-Dgtk3=true
		-Dgtk4=false
		$(meson_use icu)
		$(meson_use systemd _systemd)
		$(meson_use vala vapi)
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	mv "${ED}"/etc/profile.d/vte{,-${SLOT}}.sh || die
}
