import 'dart:ui' show Locale;

/// The interface's words, in English and Arabic.
///
/// A plain map rather than generated ARB files, on purpose: the shop's Arabic is
/// the shop's own Arabic — عميل or زبون, وديعة or دفعة مقدمة — and the person who
/// owns that vocabulary is the owner, not a translator's default. Keeping the
/// pairs in one file makes that conversation cheap, and a missing key falls back
/// to English instead of showing a blank or a `key.not.found`.
/// Keys are namespaced by area so a missing one is obvious at the call site.
const Map<String, String> _en = <String, String>{
  'nav.today': 'Today',
  'nav.orders': 'Orders',
  'nav.production': 'Production',
  'nav.customers': 'Customers',
  'nav.catalogue': 'Catalogue',
  'nav.productionSetup': 'Production setup',
  'nav.prices': 'Prices',
  'nav.reports': 'Reports',
  'nav.staff': 'Staff',
  'nav.vendors': 'Vendors',
  'nav.settings': 'Settings',
  'nav.quickSale': 'Quick sale',
  'nav.work': 'WORK',
  'nav.people': 'PEOPLE',
  'nav.business': 'BUSINESS',

  'menu.till': 'Cash drawer',
  'menu.log': 'Activity log',
  'menu.themeDark': 'Dark interface',
  'menu.themeLight': 'Light interface',
  'menu.diagnostics': 'Sync diagnostics',
  'menu.language': 'عربي — Arabic layout',
  'menu.signout': 'Sign out',

  'today.newOrder': 'New order',
  'today.inProduction': 'In production',
  'today.overdue': 'Overdue',
  'today.dueToday': 'Due today',
  'today.waitingForYou': 'Waiting for you',
  'today.overdueHint': 'past its date',
  'today.nothingLate': 'nothing late',
  'today.onMachine': 'running right now',
  'today.nothingOnMachine': 'nothing on a machine',
  'today.promisedToday': 'jobs promised today',
  'today.noPromiseToday': 'no jobs promised today',
  'today.queueClear': 'your queue is clear',
  'today.unclaimed': 'unclaimed in your role',
  'today.overdueTitle': 'Overdue',
  'today.overdueSubtitle': 'Past its promised date. Call the customer today.',
  'today.dueTodayTitle': 'Due today',
  'today.waitingTitle': 'Waiting to be picked up',
  'today.waitingSubtitle': 'Available work for your role.',
  'today.waitingSubtitleAll': 'Available work across every role.',
  'today.onCustomer': 'Waiting on the customer',
  'today.onCustomerSubtitle': 'A proof went out and has not come back. Nothing moves on these jobs until it does.',
  'today.cashToday': 'Cash today',
  'today.nothingNeedsYou': 'Nothing needs you right now',
  'today.nothingNeedsYouBody': 'New orders, due dates and unclaimed work appear here as they arrive — on this device, even with no connection.',

  'common.board': 'Board',
  'common.myWork': 'My work',
  'common.open': 'Open',
  'common.refresh': 'Refresh',
};

const Map<String, String> _ar = <String, String>{
  'nav.today': 'اليوم',
  'nav.orders': 'الطلبات',
  'nav.production': 'الإنتاج',
  'nav.customers': 'العملاء',
  'nav.catalogue': 'الكتالوج',
  'nav.productionSetup': 'إعداد الإنتاج',
  'nav.prices': 'الأسعار',
  'nav.reports': 'التقارير',
  'nav.staff': 'الموظفون',
  'nav.vendors': 'الموردون',
  'nav.settings': 'الإعدادات',
  'nav.quickSale': 'بيع سريع',
  'nav.work': 'العمل',
  'nav.people': 'الأشخاص',
  'nav.business': 'الإدارة',

  'menu.till': 'درج النقد',
  'menu.log': 'سجل النشاط',
  'menu.themeDark': 'الواجهة الداكنة',
  'menu.themeLight': 'الواجهة الفاتحة',
  'menu.diagnostics': 'تشخيص المزامنة',
  'menu.language': 'English interface',
  'menu.signout': 'تسجيل الخروج',

  'today.newOrder': 'طلب جديد',
  'today.inProduction': 'قيد التنفيذ',
  'today.overdue': 'متأخر',
  'today.dueToday': 'مستحق اليوم',
  'today.waitingForYou': 'بانتظارك',
  'today.overdueHint': 'تجاوز موعده',
  'today.nothingLate': 'لا شيء متأخر',
  'today.onMachine': 'يعمل الآن',
  'today.nothingOnMachine': 'لا شيء على الماكينة',
  'today.promisedToday': 'طلبات موعده اليوم',
  'today.noPromiseToday': 'لا مواعيد اليوم',
  'today.queueClear': 'قائمة عملك فارغة',
  'today.unclaimed': 'غير مستلم في دورك',
  'today.overdueTitle': 'متأخر',
  'today.overdueSubtitle': 'تجاوز الموعد المتفق عليه. اتصل بالعميل اليوم.',
  'today.dueTodayTitle': 'مستحق اليوم',
  'today.waitingTitle': 'بانتظار من يستلمه',
  'today.waitingSubtitle': 'عمل متاح لدورك.',
  'today.waitingSubtitleAll': 'عمل متاح لكل الأدوار.',
  'today.onCustomer': 'بانتظار العميل',
  'today.onCustomerSubtitle':
      'أُرسلت النسخة ولم تُعتمد بعد. لا يتقدم العمل حتى يعود الرد.',
  'today.cashToday': 'نقد اليوم',
  'today.nothingNeedsYou': 'لا شيء يتطلب انتباهك الآن',
  'today.nothingNeedsYouBody': 'تظهر هنا الطلبات الجديدة والمواعيد والعمل غير المستلم فور وصولها — على هذا الجهاز، حتى بدون اتصال.',

  'common.board': 'لوحة الإنتاج',
  'common.myWork': 'عملي',
  'common.open': 'فتح',
  'common.refresh': 'تحديث',
};

class AppStrings {
  const AppStrings(this._values);

  final Map<String, String> _values;

  /// Arabic when the locale says so, English otherwise. A partial translation
  /// shows English for the missing keys rather than a placeholder.
  factory AppStrings.of(Locale? locale) => locale?.languageCode == 'ar'
      ? const AppStrings(_ar)
      : const AppStrings(_en);

  String call(String key) => _values[key] ?? _en[key] ?? key;
}
