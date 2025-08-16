return {
  cog = {
    name="Cog Turret",
    cost=50, range=140, fireRate=1.0, damage=20, bulletSpeed=320,
    upgrade = {
      {cost=45, damage=28, range=150, fireRate=1.2},
      {cost=70, damage=38, range=165, fireRate=1.4},
      {cost=100, damage=52, range=180, fireRate=1.6},
    }
  },
  tesla = {
    name="Tesla Coil",
    cost=90, range=130, dps=28, chains=3,
    upgrade = {
      {cost=70, dps=40, range=145, chains=3},
      {cost=100, dps=56, range=160, chains=3},
      {cost=140, dps=78, range=175, chains=3},
    }
  },
  mortar = {
    name="Steam Mortar",
    cost=90, range=200, splash=70, damage=24, fireRate=0.6, projSpeed=220,
    upgrade = {
      {cost=70, damage=36, splash=80, range=220, fireRate=0.7},
      {cost=100, damage=52, splash=92, range=230, fireRate=0.8},
      {cost=140, damage=72, splash=105, range=240, fireRate=0.9},
    }
  },
  cat = {
    name="Cat-a-pult",
    cost=75, range=155, fireRate=1.1, damage=22, bulletSpeed=300,
    slowPct=0.35, slowDur=1.2,
    upgrade = {
      {cost=60, damage=30, range=170, fireRate=1.25, slowPct=0.40, slowDur=1.3},
      {cost=90, damage=40, range=185, fireRate=1.45, slowPct=0.45, slowDur=1.4},
      {cost=130, damage=56, range=200, fireRate=1.65, slowPct=0.50, slowDur=1.5},
    }
  }
}
