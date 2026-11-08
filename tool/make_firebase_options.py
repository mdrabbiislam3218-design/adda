"""google-services.json থেকে lib/firebase_options.dart বানায়।

কম্পিউটারে flutterfire configure চালানোর বদলে অনলাইন বিল্ডে এই স্ক্রিপ্ট চলে।
"""
import json
import pathlib
import sys

PACKAGE = "com.adda.adda"

src = pathlib.Path("google-services.json")
if not src.exists():
    sys.exit("google-services.json পাওয়া যায়নি")

data = json.loads(src.read_text(encoding="utf-8"))
info = data["project_info"]
clients = data["client"]

client = None
for c in clients:
    if c["client_info"]["android_client_info"]["package_name"] == PACKAGE:
        client = c
        break
if client is None:
    names = [c["client_info"]["android_client_info"]["package_name"] for c in clients]
    sys.exit(f"google-services.json এ {PACKAGE} নামের Android অ্যাপ নেই। পাওয়া গেছে: {names}")

fields = {
    "apiKey": client["api_key"][0]["current_key"],
    "appId": client["client_info"]["mobilesdk_app_id"],
    "messagingSenderId": info["project_number"],
    "projectId": info["project_id"],
}
if info.get("storage_bucket"):
    fields["storageBucket"] = info["storage_bucket"]

body = "\n".join(f"    {k}: {json.dumps(v)}," for k, v in fields.items())
dart = f"""// স্বয়ংক্রিয়ভাবে তৈরি (tool/make_firebase_options.py)। হাতে বদলাবেন না।
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {{
  static const FirebaseOptions currentPlatform = FirebaseOptions(
{body}
  );
}}
"""

out = pathlib.Path("lib/firebase_options.dart")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(dart, encoding="utf-8")
print("lib/firebase_options.dart তৈরি হয়েছে")
