# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit gnome.org gnome2-utils meson xdg virtualx

DESCRIPTION="GNOME webbrowser based on Webkit"
HOMEPAGE="https://wiki.gnome.org/Apps/Web"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~*"

IUSE="portal test"

RESTRICT="!test? ( test )"

DEPEND="
	>=dev-libs/glib-2.61.2:2
	>=x11-libs/gtk+-3.24.0:3
	>=dev-libs/nettle-3.4:=
	>=net-libs/webkit-gtk-2.29.3:4=
	>=x11-libs/cairo-1.2
	>=app-crypt/gcr-3.5.5:=[gtk]
	>=x11-libs/gdk-pixbuf-2.36.5:2
	gnome-base/gsettings-desktop-schemas
	>=app-text/iso-codes-0.35
	>=dev-libs/json-glib-1.2.4
	>=dev-libs/libdazzle-3.37.1
	>=gui-libs/libhandy-1.0.0:1.0=
	>=app-crypt/libsecret-0.19.0
	>=net-libs/libsoup-2.48.0:2.4
	>=dev-libs/libxml2-2.6.12:2
	dev-db/sqlite:3
	dev-libs/gmp:0=
	portal? ( >=sys-apps/xdg-desktop-portal-0.0.2 )
"
RDEPEND="${DEPEND}
	x11-themes/adwaita-icon-theme
"
# appstream-glib needed for appdata.xml gettext translation
BDEPEND="
	dev-libs/appstream-glib
	dev-util/gdbus-codegen
	dev-util/itstool
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
"

PATCHES=(
	# Allow /var/tmp prefixed recursive delete (due to package manager setting TMPDIR)
	"${FILESDIR}"/var-tmp-tests.patch

	# From GNOME:
	# 	https://gitlab.gnome.org/GNOME/epiphany/commit/afd155430075cee5380334a9c263cc28426fc79c
	"${FILESDIR}"/${PN}-3.38.1-build-allow-libportal-support-to-be-disabled.patch
)

src_configure() {
	local emesonargs=(
		-Ddeveloper_mode=false
		# maybe enable later if network-sandbox is off, but in 3.32.4 the network test
		# is commented out upstream anyway
		$(meson_feature portal libportal)
		-Dnetwork_tests=disabled
		-Dtech_preview=false
		$(meson_feature test unit_tests)
	)
	meson_src_configure
}

src_install() {
	meson_src_install

	# Do not install files owned by libhandy
	rm -f "${ED}"/usr/include/libhandy-*/handy.h
	rm -f "${ED}"/usr/include/libhandy-*/hdy-*.h
	rm -f "${ED}"/usr/lib*/girepository-1.0/Handy-*typelib
	rm -f "${ED}"/usr/lib*/libhandy-*.so
	rm -f "${ED}"/usr/lib*/libhandy-*.so.0
	rm -f "${ED}"/usr/lib*/pkgconfig/libhandy-*.pc
	rm -f "${ED}"/usr/share/gir-1.0/Handy-0.0.gir
	rm -f "${ED}"/usr/share/vala/vapi/libhandy-*.deps
	rm -f "${ED}"/usr/share/vala/vapi/libhandy-*.vapi
}

src_test() {
	virtx meson_src_test
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update

	if ! has_version net-libs/webkit-gtk[jpeg2k]; then
		ewarn "Your net-libs/webkit-gtk is built without USE=jpeg2k."
		ewarn "Various image galleries/managers may be broken."
	fi
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
