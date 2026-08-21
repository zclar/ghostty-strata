#define _GNU_SOURCE
#include <dlfcn.h>
#include <stddef.h>
#include <stdlib.h>
#include <unistd.h>

typedef unsigned long GType;
typedef unsigned int guint;
typedef int gboolean;
typedef struct _GValue GValue;
typedef struct _GSignalInvocationHint GSignalInvocationHint;

typedef GType (*get_type_fn)(void);
typedef guint (*signal_lookup_fn)(const char *, GType);
typedef unsigned long (*signal_hook_fn)(guint, unsigned long,
    gboolean (*)(GSignalInvocationHint *, guint, const GValue *, void *),
    void *, void (*)(void *));
typedef void *(*value_object_fn)(const GValue *);
typedef gboolean (*type_check_fn)(void *, GType);
typedef void (*css_class_fn)(void *, const char *);
typedef guint (*idle_add_fn)(gboolean (*)(void *), void *);
typedef guint (*timeout_add_fn)(guint, gboolean (*)(void *), void *);
typedef void *(*object_ref_fn)(void *);
typedef void (*object_unref_fn)(void *);
typedef gboolean (*widget_mapped_fn)(void *);

static GType popover_type;
static value_object_fn value_object;
static type_check_fn type_check;
static css_class_fn add_class;
static css_class_fn remove_class;
static object_unref_fn object_unref;
static widget_mapped_fn widget_mapped;
static int installed;

static void install_hooks(void);

static gboolean install_from_idle(void *data) {
  (void)data;
  (void)write(2, "strata-popover: idle\n", 21);
  install_hooks();
  return 0;
}

__attribute__((constructor))
static void strata_load(void) {
  (void)write(2, "strata-popover: load\n", 21);
  idle_add_fn idle_add = dlsym(RTLD_DEFAULT, "g_idle_add");
  if (idle_add) {
    idle_add(install_from_idle, NULL);
  } else {
    (void)write(2, "strata-popover: no idle\n", 24);
  }
}

static gboolean deploy_after_frame(void *data) {
  void *widget = data;
  if (widget_mapped(widget))
    add_class(widget, "strata-deploy");
  object_unref(widget);
  return 0;
}

static gboolean on_map(GSignalInvocationHint *hint, guint count,
                       const GValue *values, void *data) {
  (void)hint; (void)count; (void)data;
  void *widget = value_object(values);
  if (widget && type_check(widget, popover_type)) {
    timeout_add_fn timeout_add = dlsym(RTLD_DEFAULT, "g_timeout_add");
    object_ref_fn object_ref = dlsym(RTLD_DEFAULT, "g_object_ref");
    remove_class(widget, "strata-deploy");
    if (timeout_add && object_ref)
      timeout_add(34, deploy_after_frame, object_ref(widget));
    write(2, "strata-popover: map\n", 20);
  }
  return 1;
}

static gboolean on_unmap(GSignalInvocationHint *hint, guint count,
                         const GValue *values, void *data) {
  (void)hint; (void)count; (void)data;
  void *widget = value_object(values);
  if (widget && type_check(widget, popover_type)) {
    remove_class(widget, "strata-deploy");
    write(2, "strata-popover: unmap\n", 22);
  }
  return 1;
}

static void install_hooks(void) {
  if (installed) return;

  get_type_fn widget_get_type = dlsym(RTLD_DEFAULT, "gtk_widget_get_type");
  get_type_fn popover_get_type = dlsym(RTLD_DEFAULT, "gtk_popover_get_type");
  signal_lookup_fn signal_lookup = dlsym(RTLD_DEFAULT, "g_signal_lookup");
  signal_hook_fn add_hook = dlsym(RTLD_DEFAULT, "g_signal_add_emission_hook");
  value_object = dlsym(RTLD_DEFAULT, "g_value_get_object");
  type_check = dlsym(RTLD_DEFAULT, "g_type_check_instance_is_a");
  add_class = dlsym(RTLD_DEFAULT, "gtk_widget_add_css_class");
  remove_class = dlsym(RTLD_DEFAULT, "gtk_widget_remove_css_class");
  object_unref = dlsym(RTLD_DEFAULT, "g_object_unref");
  widget_mapped = dlsym(RTLD_DEFAULT, "gtk_widget_get_mapped");

  if (!widget_get_type || !popover_get_type || !signal_lookup || !add_hook ||
      !value_object || !type_check || !add_class || !remove_class ||
      !object_unref || !widget_mapped) return;

  GType widget_type = widget_get_type();
  popover_type = popover_get_type();
  guint map_signal = signal_lookup("map", widget_type);
  guint unmap_signal = signal_lookup("unmap", widget_type);
  if (!map_signal || !unmap_signal) return;

  installed = 1;
  if (map_signal) {
    add_hook(map_signal, 0, on_map, NULL, NULL);
    (void)write(2, "strata-popover: map hook\n", 25);
  }
  if (unmap_signal) {
    add_hook(unmap_signal, 0, on_unmap, NULL, NULL);
    (void)write(2, "strata-popover: unmap hook\n", 27);
  }
}
