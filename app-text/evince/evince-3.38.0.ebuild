# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit gnome.org gnome2-utils meson systemd

DESCRIPTION="Simple document viewer for GNOME"
HOMEPAGE="https://wiki.gnome.org/Apps/Evince"

LICENSE="GPL-2+ CC-BY-SA-3.0"
# subslot = evd3.(suffix of libevdocument3)-evv3.(suffix of libevview3)
SLOT="0/evd3.4-evv3.3"
KEYWORDS="*"

IUSE="dbus djvu doc dvi gstreamer gnome gnome-keyring gtk-doc +introspection nautilus nsplugin postscript spell t1lib tiff xps"

# atk used in libview
# bundles unarr
COMMON_DEPEND="
	dev-libs/atk
	>=dev-libs/glib-2.44.0:2[dbus]
	>=dev-libs/libxml2-2.5:2
	sys-libs/zlib:=
	>=x11-libs/gdk-pixbuf-2.40.0:2
	>=x11-libs/gtk+-3.22.0:3[introspection?]
	gnome-base/gsettings-desktop-schemas
	>=x11-libs/cairo-1.10:=
	>=app-text/poppler-0.33[cairo]
	>=app-arch/libarchive-3.2.0
	dbus? ( sys-apps/dbus )
	djvu? ( >=app-text/djvu-3.5.22:= )
	dvi? (
		virtual/tex-base
		dev-libs/kpathsea:=
		t1lib? ( >=media-libs/t1lib-5:= ) )
	gstreamer? (
		media-libs/gstreamer:1.0
		media-libs/gst-plugins-base:1.0
		media-libs/gst-plugins-good:1.0 )
	gnome? ( gnome-base/gnome-desktop:3= )
	gnome-keyring? ( >=app-crypt/libsecret-0.5 )
	introspection? ( >=dev-libs/gobject-introspection-1:= )
	nautilus? ( >=gnome-base/nautilus-3.28.0 )
	postscript? ( >=app-text/libspectre-0.2:= )
	spell? ( >=app-text/gspell-1.6.0:= )
	tiff? ( >=media-libs/tiff-3.6:0= )
	xps? ( >=app-text/libgxps-0.2.1:= )
"
RDEPEND="${COMMON_DEPEND}
	gnome-base/gvfs
	gnome-base/librsvg
	|| (
		>=x11-themes/adwaita-icon-theme-2.17.1
		>=x11-themes/hicolor-icon-theme-0.10 )
"
DEPEND="${COMMON_DEPEND}
	app-text/docbook-xml-dtd:4.3
	dev-libs/appstream-glib
	dev-util/gdbus-codegen
	gtk-doc? ( >=dev-util/gtk-doc-am-1.13 )
	dev-util/itstool
	sys-devel/gettext
	virtual/pkgconfig
	app-text/yelp-tools
"

src_configure() {
	local emesonargs=(
		-Dplatform="gnome"
		-Dviewer=true
		-Dpreviewer=true
		-Dthumbnailer=true
		$(meson_use nsplugin browser_plugin)
		$(meson_use nautilus)
		-Dcomics=enabled
		$(meson_feature djvu)
		$(meson_feature dvi)
		-Dpdf=enabled
		$(meson_feature postscript ps)
		$(meson_feature tiff)
		$(meson_feature xps)
		$(meson_use gtk-doc gtk_doc)
		$(meson_use doc user_doc)
		$(meson_use introspection)
		$(meson_use dbus)
		$(meson_feature gnome-keyring keyring)
		-Dgtk_unix_print=enabled
		-Dthumbnail_cache=enabled
		$(meson_feature gstreamer multimedia)
		$(meson_feature spell gspell)
		$(meson_feature t1lib)
		-Dbrowser_plugin_dir="${EPREFIX}"/usr/$(get_libdir)/nsbrowser/plugins
		-Dsystemduserunitdir="$(systemd_get_userunitdir)"
	)
	meson_src_configure
}
