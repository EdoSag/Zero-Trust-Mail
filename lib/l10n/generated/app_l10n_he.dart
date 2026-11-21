// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppL10nHe extends AppL10n {
  AppL10nHe([String locale = 'he']) : super(locale);

  @override
  String get settings => 'הגדרות';

  @override
  String get cancel => 'ביטול';

  @override
  String get save => 'שמירה';

  @override
  String get remove => 'הסרה';

  @override
  String get accounts => 'חשבונות דואר';

  @override
  String get addAccount => 'הוספת חשבון';

  @override
  String get editAccount => 'עריכת חשבון';

  @override
  String get noAccountsTitle => 'הוסיפו את חשבון הדואר הראשון';

  @override
  String get noAccountsBody =>
      'אפשר להשתמש בדואר שכבר יש לכם: Gmail, Outlook, iCloud או כל ספק אחר. הסיסמה נשארת בטלפון הזה.';

  @override
  String get comingSoon =>
      'קריאה ושליחה של דואר יגיעו בעדכון הבא. החשבונות שלכם שמורים ומוכנים.';

  @override
  String get passwordNeeded => 'נדרשת סיסמה בטלפון הזה';

  @override
  String get protocolImap => 'IMAP';

  @override
  String get protocolJmap => 'JMAP';

  @override
  String get protocolZtMailbox => 'תיבת ZT Mail';

  @override
  String get yourName => 'השם שלכם';

  @override
  String get yourNameHint => 'מוצג לאנשים שאתם כותבים להם';

  @override
  String get email => 'כתובת אימייל';

  @override
  String get password => 'סיסמה';

  @override
  String get passwordKeep => 'השאירו ריק כדי לשמור על הסיסמה הקיימת';

  @override
  String appPasswordHint(String provider) {
    return '$provider דורש סיסמת אפליקציה ולא את הסיסמה הרגילה. יוצרים אותה בהגדרות האבטחה של חשבון $provider.';
  }

  @override
  String get serverSettings => 'הגדרות שרת';

  @override
  String get incomingServer => 'שרת דואר נכנס (IMAP)';

  @override
  String get outgoingServer => 'שרת דואר יוצא (SMTP)';

  @override
  String get port => 'פורט';

  @override
  String get username => 'שם כניסה';

  @override
  String get usernameHint => 'רק אם הוא שונה מכתובת האימייל';

  @override
  String get invalidEmail => 'הזינו כתובת אימייל תקינה';

  @override
  String get invalidHost => 'הזינו שם שרת, למשל imap.example.com';

  @override
  String get invalidPort => 'הזינו פורט בין 1 ל-65535';

  @override
  String get passwordRequired => 'הזינו את הסיסמה';

  @override
  String get accountExists => 'החשבון הזה כבר נוסף';

  @override
  String get accountSaved => 'החשבון נשמר';

  @override
  String get removeAccountTitle => 'להסיר את החשבון?';

  @override
  String removeAccountBody(String email) {
    return '$email יוסר מ-ZT Mail בכל המכשירים שלכם. הדואר נשאר אצל הספק.';
  }

  @override
  String get accountRemoved => 'החשבון הוסר';

  @override
  String get saveFailed => 'השמירה נכשלה. נסו שוב.';
}
