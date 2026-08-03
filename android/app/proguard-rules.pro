# Regras extras do R8 além das que os plugins já embarcam (consumer rules).

# flutter_local_notifications: (de)serializa notificações agendadas com
# Gson — sem manter os TypeToken/Signature, o restore quebra em release.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
