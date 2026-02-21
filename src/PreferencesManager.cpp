#include "PreferencesManager.h"

PreferencesManager *PreferencesManager::m_instance = nullptr;

PreferencesManager *PreferencesManager::instance() { return m_instance; }
