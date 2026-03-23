import 'dart:ui';

class Config {
  static const double playerSpeed = 200.0;
  static const double playerSize = 20.0;
  static const int playerMaxHp = 5;
  static const double playerMaxMp = 100.0;
  static const double mpRegen = 5.0;
  static const double invincibleDuration = 1.2;
  static const double dashSpeed = 500.0;
  static const double dashDuration = 0.18;
  static const double dashCooldown = 1.5;

  static const double attackRange = 35.0;
  static const double attackWidth = 50.0;
  static const int attackDamage = 1;
  static const int comboFinisherDamage = 3;
  static const double comboWindow = 0.4;
  static const double attackDuration = 0.15;
  static const double attackCooldown = 0.25;

  static const double wolfSpeed = 80.0;
  static const double wolfSize = 16.0;
  static const int wolfHp = 2;
  static const double wolfDamage = 1;
  static const double wolfLungeSpeed = 250.0;
  static const double wolfLungeRange = 100.0;
  static const double wolfLungeCooldown = 3.0;
  static const double wolfAggroRange = 180.0;

  static const double golemSpeed = 40.0;
  static const double golemSize = 24.0;
  static const int golemHp = 6;
  static const int golemDamage = 2;
  static const double golemSlamRange = 60.0;
  static const double golemSlamCooldown = 3.5;
  static const double golemSlamRadius = 70.0;
  static const double golemSlamWindup = 0.6;
  static const double golemAggroRange = 160.0;

  static const double knightSpeed = 55.0;
  static const double knightSize = 18.0;
  static const int knightHp = 4;
  static const int knightDamage = 2;
  static const double knightBlockArc = 1.2;
  static const double knightSlashRange = 45.0;
  static const double knightSlashCooldown = 2.0;
  static const double knightAggroRange = 170.0;

  static const double bossStatueSize = 50.0;
  static const int bossStatueHpPhase1 = 20;
  static const int bossStatueHpTotal = 40;
  static const double bossStatueFistRange = 90.0;
  static const double bossStatueFistCooldown = 2.5;
  static const double bossStatueFistRadius = 80.0;
  static const double bossStatueLaserCooldown = 4.0;
  static const double bossStatueLaserDuration = 1.5;
  static const double bossStatueLaserWidth = 30.0;

  static const double shadowGaugeMax = 100.0;
  static const double shadowGainPerKill = 12.0;
  static const double shadowGainPerEliteKill = 35.0;

  static const double roomWidth = 800.0;
  static const double roomHeight = 600.0;
  static const double wallThickness = 16.0;
  static const double tileSize = 32.0;
  static const double doorWidth = 48.0;
  static const double pillarSize = 24.0;

  static const Color playerColor = Color(0xFF9B6DD7);
  static const Color playerGlow = Color(0xFF6B3FA0);
  static const Color enemyColor = Color(0xFFE65100);
  static const Color enemyEliteColor = Color(0xFFDC143C);
  static const Color bossColor = Color(0xFFFF3030);
  static const Color shadowColor = Color(0xFF3D1F6D);
  static const Color healthColor = Color(0xFFDC143C);
  static const Color mpColor = Color(0xFF2196F3);
  static const Color shadowGaugeColor = Color(0xFF9B6DD7);
  static const Color bgColor = Color(0xFF0A0A0C);
  static const Color wallColor = Color(0xFF1A1A2E);
  static const Color floorColor = Color(0xFF0D0D12);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color golemColor = Color(0xFF78909C);
  static const Color golemCoreColor = Color(0xFFFF6D00);
  static const Color knightColor = Color(0xFF90A4AE);
  static const Color knightShieldColor = Color(0xFF546E7A);
  static const Color doorLockedColor = Color(0xFF4A1A1E);
  static const Color doorOpenColor = Color(0xFF2A6A3E);
  static const Color healColor = Color(0xFF4CAF50);

  static const Color menuPrimaryColor = Color(0xFF6B3FA0);
  static const Color menuAccentColor = Color(0xFF1A0A3E);
  static const Color menuGlowColor = Color(0xFF9B6DD7);
  static const Color menuParticleColor = Color(0xFF5A3D8A);
  static const int menuParticleCount = 80;
  static const double menuParticleSpeed = 20.0;
  static const double menuPulseSpeed = 2.0;
  static const int menuSilhouetteCount = 4;

  static const String menuBgmFile = 'menu_bgm.mp3';
  static const double menuBgmVolume = 0.6;
}
