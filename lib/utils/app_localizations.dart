import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

    static final Map<String, Map<String, String>> _localizedValues = {    'en': {      'citizen_dashboard': 'Citizen Dashboard',      'citizen': 'Citizen',      'home': 'Home',      'polls': 'Polls',      'report': 'Report',      'emergency': 'Emergency',      'announcements': 'Announcements',      'comments': 'Comments',      'add_comment': 'Add a comment...',      'no_comments': 'No comments yet',      'submit': 'Submit',      'welcome_back': 'Welcome Back',      'login_subtitle': 'Sign in to access government services',      'email': 'Email',      'email_hint': 'Enter your email address',      'email_required': 'Email is required',      'invalid_email': 'Please enter a valid email',      'password': 'Password',      'password_hint': 'Enter your password',      'password_required': 'Password is required',      'password_length': 'Password must be at least 6 characters',      'login': 'Login',      'no_account': 'Don\'t have an account? ',      'sign_up': 'Sign Up',      'forgot_password': 'Forgot Password?',      'report_issue': 'Report Issue',      'issue_description': 'Issue Description',      'upload_photo': 'Upload Photo',      'photo_selected': 'Photo Selected',      'submit_report': 'Submit Report',      'please_fill_fields': 'Please fill all fields',      'issue_reported': 'Issue reported successfully',      'error_reporting': 'Failed to report issue',      'emergency_numbers': 'Emergency Numbers',      'police': 'Police',      'ambulance': 'Ambulance',      'fire_department': 'Fire Department',      'vote': 'Vote',      'already_voted': 'You have already voted',      'vote_submitted': 'Vote submitted successfully',      'error_voting': 'Error submitting vote',      'please_login': 'Please login',      'logout': 'Logout',      // Poll Card Translations      'please_login_to_vote': 'Please login to vote',      'only_citizens_can_vote': 'Only citizens can vote in polls',      'already_voted_in_poll': 'You have already voted in this poll',      'vote_success': 'Vote submitted successfully!',      'vote_error': 'Error submitting vote',      'attachments': 'Attachments',      'view_attachment': 'View Attachment',      'no_announcements': 'No announcements available.',      'error_loading_announcements': 'Error loading announcements',      'error_loading_comments': 'Error loading comments',
      'create_account': 'Create Account',
      'signup_subtitle': 'Join us to access government services',
      'full_name': 'Full Name',
      'full_name_hint': 'Enter your full name',
      'name_required': 'Full name is required',
      'confirm_password': 'Confirm Password',
      'confirm_password_hint': 'Re-enter your password',
      'confirm_password_required': 'Please confirm your password',
      'passwords_not_match': 'Passwords do not match',
      'have_account': 'Already have an account? ',
    },
    'ar': {
      'citizen_dashboard': 'لوحة تحكم المواطن',
      'citizen': 'مواطن',
      'home': 'الرئيسية',
      'polls': 'استطلاعات',
      'report': 'بلاغ',
      'emergency': 'طوارئ',
      'announcements': 'الإعلانات',
      'comments': 'التعليقات',
      'add_comment': 'أضف تعليقاً...',
      'no_comments': 'لا توجد تعليقات',
      'submit': 'إرسال',
      'welcome_back': 'مرحباً بعودتك',
      'login_subtitle': 'سجل دخولك للوصول إلى الخدمات الحكومية',
      'email': 'البريد الإلكتروني',
      'email_hint': 'أدخل بريدك الإلكتروني',
      'email_required': 'البريد الإلكتروني مطلوب',
      'invalid_email': 'يرجى إدخال بريد إلكتروني صحيح',
      'password': 'كلمة المرور',
      'password_hint': 'أدخل كلمة المرور',
      'password_required': 'كلمة المرور مطلوبة',
      'password_length': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'login': 'تسجيل الدخول',
      'no_account': 'ليس لديك حساب؟ ',
      'sign_up': 'إنشاء حساب',
      'forgot_password': 'نسيت كلمة المرور؟',
      'report_issue': 'الإبلاغ عن مشكلة',
      'issue_description': 'وصف المشكلة',
      'upload_photo': 'رفع صورة',
      'photo_selected': 'تم اختيار الصورة',
      'submit_report': 'إرسال البلاغ',
      'please_fill_fields': 'يرجى تعبئة جميع الحقول',
      'issue_reported': 'تم إرسال البلاغ بنجاح',
      'error_reporting': 'فشل في إرسال البلاغ',
      'emergency_numbers': 'أرقام الطوارئ',
      'police': 'الشرطة',
      'ambulance': 'الإسعاف',
      'fire_department': 'الدفاع المدني',
      'vote': 'تصويت',
      'already_voted': 'لقد قمت بالتصويت مسبقاً',
      'vote_submitted': 'تم إرسال تصويتك بنجاح',
      'error_voting': 'خطأ في إرسال التصويت',
      'please_login': 'يرجى تسجيل الدخول',
      'logout': 'تسجيل خروج',
      'create_account': 'إنشاء حساب',
      'signup_subtitle': 'انضم إلينا للوصول إلى الخدمات الحكومية',
      'full_name': 'الاسم الكامل',
      'full_name_hint': 'أدخل اسمك الكامل',
      'name_required': 'الاسم الكامل مطلوب',
      'confirm_password': 'تأكيد كلمة المرور',
      'confirm_password_hint': 'أعد إدخال كلمة المرور',
      'confirm_password_required': 'يرجى تأكيد كلمة المرور',
      'passwords_not_match': 'كلمات المرور غير متطابقة',
      'have_account': 'لديك حساب بالفعل؟ ',
    },
  };

  String get currentLanguage => locale.languageCode;

  String translate(String key) {
    return _localizedValues[currentLanguage]?[key] ?? key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 