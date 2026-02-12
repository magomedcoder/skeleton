#include "my_application.h"

#include <gdk-pixbuf/gdk-pixbuf.h>
#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static GtkWindow* g_main_window = nullptr;
static GtkStatusIcon* g_status_icon = nullptr;

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

static void status_icon_activate_cb(GtkStatusIcon* icon, gpointer user_data) {
  (void)icon;
  (void)user_data;
  if (g_main_window) {
    gtk_widget_show(GTK_WIDGET(g_main_window));
    gtk_window_present(g_main_window);
  }
}

static void status_icon_popup_menu_cb(
    GtkStatusIcon* icon,
    guint button,
    guint activate_time,
    gpointer user_data
) {
  (void)user_data;
  if (button != 3) return;
  GtkWidget* menu = gtk_menu_new();
  GtkWidget* quit_item = gtk_menu_item_new_with_label("Выход");
  g_signal_connect_swapped(
      quit_item,
      "activate",
      G_CALLBACK(gtk_main_quit),
      nullptr
  );
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), quit_item);
  gtk_widget_show_all(menu);
  gtk_menu_popup_at_pointer(GTK_MENU(menu), nullptr);
}

static gboolean window_delete_cb(
    GtkWidget* widget,
    GdkEvent* event,
    gpointer user_data
) {
  (void)widget;
  (void)event;
  (void)user_data;
  gtk_widget_hide(GTK_WIDGET(g_main_window));
  if (!g_status_icon) {
    g_status_icon = gtk_status_icon_new_from_file("linux/runner/resources/app_icon.png");
    gtk_status_icon_set_tooltip_text(g_status_icon, "Legion");
    g_signal_connect(
        g_status_icon,
        "activate",
        G_CALLBACK(status_icon_activate_cb),
        nullptr
    );
    g_signal_connect(
        g_status_icon,
        "popup-menu",
        G_CALLBACK(status_icon_popup_menu_cb),
        nullptr
    );
  }
  gtk_status_icon_set_visible(g_status_icon, TRUE);
  return TRUE;
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  if (g_main_window) {
    gtk_widget_show(GTK_WIDGET(g_main_window));
    gtk_window_present(g_main_window);
    return;
  }

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  g_main_window = window;
  g_signal_connect(
        window,
        "delete-event",
        G_CALLBACK(window_delete_cb),
        nullptr
    );

    GdkPixbuf *icon = gdk_pixbuf_new_from_file("linux/runner/resources/app_icon.png", nullptr);
    if (icon != nullptr) {
        gtk_window_set_icon(window, icon);
        g_object_unref(icon);
    } else {
        g_warning("Не удалось загрузить иконку из linux/runner/resources/app_icon.png");
    }

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Legion");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Legion");
  }

  gtk_window_set_default_size(window, 1280, 720);

  GdkGeometry geometry = {};
  geometry.min_width = 800;
  geometry.min_height = 600;
  gtk_window_set_geometry_hints(
    window, 
    nullptr,
    &geometry,
    static_cast<GdkWindowHints>(GDK_HINT_MIN_SIZE)
  );

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

static void my_application_shutdown_cleanup(GApplication* application) {
  if (g_status_icon) {
    gtk_status_icon_set_visible(g_status_icon, FALSE);
    g_object_unref(g_status_icon);
    g_status_icon = nullptr;
  }
  g_main_window = nullptr;
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  my_application_shutdown_cleanup(application);
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, nullptr));
}
