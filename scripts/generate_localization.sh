# This script generates localization keys using easy_localization package

# Run the easy_localization generator
flutter pub run easy_localization:generate \
    -o lib/presentation/localization \
    -f keys \
    -o locale_keys.g.dart \
    -S assets/translations \
    -O lib/presentation/localization/