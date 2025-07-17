# coding: utf-8

with open(r'ptcg.gbc', 'rb') as f:
    data = f.read()
with open(r'text.txt', 'r') as f:
    texttable = f.readlines()
with open(r'anims.txt', 'r') as f:
    animtable = f.readlines()

offset = 0

def db():
    global offset
    r = data[offset]
    offset += 1
    return r

def dw():
    global offset
    r = data[offset+1]*256 + data[offset]
    offset += 2
    return r

def hi(x):
    return x >> 4

def lo(x):
    return x & 0xf

def tx():
    txid = dw()
    if txid >= len(texttable):
        return "$%.4x [???]" % (txid,)
    else:
        return "$%.4x [%s]" % (txid, texttable[txid].strip())

def anim():
    animid = db()
    if animid >= len(animtable):
        return "$%.2x [???]" % (animid,)
    else:
        return "$%.2x [%s]" % (animid, animtable[animid].strip())
    
eff_consts = [
    "NULL",
    "EFFECTCMDTYPE_INITIAL_EFFECT_1",
    "EFFECTCMDTYPE_INITIAL_EFFECT_2",
    "EFFECTCMDTYPE_BEFORE_DAMAGE",
    "EFFECTCMDTYPE_AFTER_DAMAGE",
    "EFFECTCMDTYPE_REQUIRE_SELECTION",
    "EFFECTCMDTYPE_DISCARD_ENERGY",
    "EFFECTCMDTYPE_PKMN_POWER_TRIGGER",
    "EFFECTCMDTYPE_AI_SELECTION",
    "EFFECTCMDTYPE_AI",
    "EFFECTCMDTYPE_AI_SWITCH_DEFENDING_PKMN"
]

def dump_energy(x):
    print("Energy: $%.2x $%.2x $%.2x $%.2x {" % x)
    def energy(t, v):
        if v == 0: return
        print("    %s: %i" % (t, v))
    energy("FIRE", hi(x[0]))
    energy("GRASS", lo(x[0]))
    energy("LIGHTNING", hi(x[1]))
    energy("WATER", lo(x[1]))
    energy("FIGHTING", hi(x[2]))
    energy("PSYCHIC", lo(x[2]))
    energy("COLORLESS", hi(x[3]))
    energy("UNUSED_POISON", lo(x[3]))
    print("}")

def dump_effect(x):
    print("Effect Ptr: %.4x {" % x)
    if x >= 0x8000:
        print("    IN REWRITABLE MEMORY")
    else:
        orig_ptr = x
        if x >= 0x4000:
            offs = 6*0x4000 + (x-0x4000)
        else:
            offs = x
        skipped = 0
        assoc = {}
        while 1:
            if orig_ptr >= 0x8000:
                print("    UNDEFINED BEHAVIOR")
                break
            if data[offs] == 0:
                break
            if data[offs] > 0xa or data[offs] == 0:
                offs += 3
                orig_ptr += 3
                skipped += 1
                continue
            if eff_consts[data[offs]] not in assoc:
                assoc[eff_consts[data[offs]]] = data[offs+1]+data[offs+2]*256
            offs += 3
            orig_ptr += 3
        for k,v in assoc.items():
            print("    %s :: $%.4x" % (k,v))
        print("    (%i invalid entries ignored)" % skipped)
    print("}")

def is_pkmn(bank, ptr):
    return data[bank*0x4000 + (ptr-0x4000)] < 0x08

def dump_all(bank, ptr):
    global offset
    offset = bank*0x4000 + (ptr-0x4000)

    print("Type: $%.2x" % db())
    print("GFX Ptr: $%.4x" % dw())
    print("Text ID: %s" % tx())
    print("Rarity: $%.2x" % db())
    print("Set: $%.2x" % db())
    print("Card ID: $%.2x" % db())
    print("Max HP: %i" % db())
    print("Stage: $%.2x" % db())
    print("Pre-Evo Name Ptr: %s" % tx())

    print()
    print("MOVE 1")
    print()

    dump_energy((db(),db(),db(),db()))
    print("Atk Name Ptr: %s" % tx())
    print("Atk Desc Ptr 1: %s" % tx())
    print("Atk Desc Ptr 2: %s" % tx())
    print("Damage: %i" % db())
    print("Dmg Type: $%.2x" % db())
    dump_effect(dw())
    print("Engine Flags: $%.2x $%.2x $%.2x" % (db(),db(),db()))
    db()
    print("Anim: %s" % anim())

    print()
    print("MOVE 2")
    print()

    dump_energy((db(),db(),db(),db()))
    print("Atk Name Ptr: %s" % tx())
    print("Atk Desc Ptr 1: %s" % tx())
    print("Atk Desc Ptr 2: %s" % tx())
    print("Damage: %i" % db())
    print("Dmg Type: $%.2x" % db())
    dump_effect(dw())
    print("Engine Flags: $%.2x $%.2x $%.2x" % (db(),db(),db()))
    db()
    print("Anim: %s" % anim())

cards = '''
0c:4e28 BulbasaurCard
0c:4e69 IvysaurCard
0c:4eaa VenusaurLv64Card
0c:4eeb VenusaurLv67Card
0c:4f2c CaterpieCard
0c:4f6d MetapodCard
0c:4fae ButterfreeCard
0c:4fef WeedleCard
0c:5030 KakunaCard
0c:5071 BeedrillCard
0c:50b2 EkansCard
0c:50f3 ArbokCard
0c:5134 NidoranFCard
0c:5175 NidorinaCard
0c:51b6 NidoqueenCard
0c:51f7 NidoranMCard
0c:5238 NidorinoCard
0c:5279 NidokingCard
0c:52ba ZubatCard
0c:52fb GolbatCard
0c:533c OddishCard
0c:537d GloomCard
0c:53be VileplumeCard
0c:53ff ParasCard
0c:5440 ParasectCard
0c:5481 VenonatCard
0c:54c2 VenomothCard
0c:5503 BellsproutCard
0c:5544 WeepinbellCard
0c:5585 VictreebelCard
0c:55c6 GrimerCard
0c:5607 MukCard
0c:5648 ExeggcuteCard
0c:5689 ExeggutorCard
0c:56ca KoffingCard
0c:570b WeezingCard
0c:574c TangelaLv8Card
0c:578d TangelaLv12Card
0c:57ce ScytherCard
0c:580f PinsirCard
0c:5850 CharmanderCard
0c:5891 CharmeleonCard
0c:58d2 CharizardCard
0c:5913 VulpixCard
0c:5954 NinetalesLv32Card
0c:5995 NinetalesLv35Card
0c:59d6 GrowlitheCard
0c:5a17 ArcanineLv34Card
0c:5a58 ArcanineLv45Card
0c:5a99 PonytaCard
0c:5ada RapidashCard
0c:5b1b MagmarLv24Card
0c:5b5c MagmarLv31Card
0c:5b9d FlareonLv22Card
0c:5bde FlareonLv28Card
0c:5c1f MoltresLv35Card
0c:5c60 MoltresLv37Card
0c:5ca1 SquirtleCard
0c:5ce2 WartortleCard
0c:5d23 BlastoiseCard
0c:5d64 PsyduckCard
0c:5da5 GolduckCard
0c:5de6 PoliwagCard
0c:5e27 PoliwhirlCard
0c:5e68 PoliwrathCard
0c:5ea9 TentacoolCard
0c:5eea TentacruelCard
0c:5f2b SeelCard
0c:5f6c DewgongCard
0c:5fad ShellderCard
0c:5fee CloysterCard
0c:602f KrabbyCard
0c:6070 KinglerCard
0c:60b1 HorseaCard
0c:60f2 SeadraCard
0c:6133 GoldeenCard
0c:6174 SeakingCard
0c:61b5 StaryuCard
0c:61f6 StarmieCard
0c:6237 MagikarpCard
0c:6278 GyaradosCard
0c:62b9 LaprasCard
0c:62fa VaporeonLv29Card
0c:633b VaporeonLv42Card
0c:637c OmanyteCard
0c:63bd OmastarCard
0c:63fe ArticunoLv35Card
0c:643f ArticunoLv37Card
0c:6480 PikachuLv12Card
0c:64c1 PikachuLv14Card
0c:6502 PikachuLv16Card
0c:6543 PikachuAltLv16Card
0c:6584 FlyingPikachuCard
0c:65c5 SurfingPikachuLv13Card
0c:6606 SurfingPikachuAltLv13Card
0c:6647 RaichuLv40Card
0c:6688 RaichuLv45Card
0c:66c9 MagnemiteLv13Card
0c:670a MagnemiteLv15Card
0c:674b MagnetonLv28Card
0c:678c MagnetonLv35Card
0c:67cd VoltorbCard
0c:680e ElectrodeLv35Card
0c:684f ElectrodeLv42Card
0c:6890 ElectabuzzLv20Card
0c:68d1 ElectabuzzLv35Card
0c:6912 JolteonLv24Card
0c:6953 JolteonLv29Card
0c:6994 ZapdosLv40Card
0c:69d5 ZapdosLv64Card
0c:6a16 ZapdosLv68Card
0c:6a57 SandshrewCard
0c:6a98 SandslashCard
0c:6ad9 DiglettCard
0c:6b1a DugtrioCard
0c:6b5b MankeyCard
0c:6b9c PrimeapeCard
0c:6bdd MachopCard
0c:6c1e MachokeCard
0c:6c5f MachampCard
0c:6ca0 GeodudeCard
0c:6ce1 GravelerCard
0c:6d22 GolemCard
0c:6d63 OnixCard
0c:6da4 CuboneCard
0c:6de5 MarowakLv26Card
0c:6e26 MarowakLv32Card
0c:6e67 HitmonleeCard
0c:6ea8 HitmonchanCard
0c:6ee9 RhyhornCard
0c:6f2a RhydonCard
0c:6f6b KabutoCard
0c:6fac KabutopsCard
0c:6fed AerodactylCard
0c:702e AbraCard
0c:706f KadabraCard
0c:70b0 AlakazamCard
0c:70f1 SlowpokeLv9Card
0c:7132 SlowpokeLv18Card
0c:7173 SlowbroCard
0c:71b4 GastlyLv8Card
0c:71f5 GastlyLv17Card
0c:7236 HaunterLv17Card
0c:7277 HaunterLv22Card
0c:72b8 GengarCard
0c:72f9 DrowzeeCard
0c:733a HypnoCard
0c:737b MrMimeCard
0c:73bc JynxCard
0c:73fd MewtwoLv53Card
0c:743e MewtwoLv60Card
0c:747f MewtwoAltLV60Card
0c:74c0 MewLv8Card
0c:7501 MewLv15Card
0c:7542 MewLv23Card
0c:7583 PidgeyCard
0c:75c4 PidgeottoCard
0c:7605 PidgeotLv38Card
0c:7646 PidgeotLv40Card
0c:7687 RattataCard
0c:76c8 RaticateCard
0c:7709 SpearowCard
0c:774a FearowCard
0c:778b ClefairyCard
0c:77cc ClefableCard
0c:780d JigglypuffLv12Card
0c:784e JigglypuffLv13Card
0c:788f JigglypuffLv14Card
0c:78d0 WigglytuffCard
0c:7911 MeowthLv14Card
0c:7952 MeowthLv15Card
0c:7993 PersianCard
0c:79d4 FarfetchdCard
0c:7a15 DoduoCard
0c:7a56 DodrioCard
0c:7a97 LickitungCard
0c:7ad8 ChanseyCard
0c:7b19 KangaskhanCard
0c:7b5a TaurosCard
0c:7b9b DittoCard
0c:7bdc EeveeCard
0c:7c1d PorygonCard
0c:7c5e SnorlaxCard
0c:7c9f DratiniCard
0c:7ce0 DragonairCard
0c:7d21 DragoniteLv41Card
0c:7d62 DragoniteLv45Card
0c:7da3 GrassEnergyCard
0c:7db1 FireEnergyCard
0c:7dbf WaterEnergyCard
0c:7dcd LightningEnergyCard
0c:7ddb FightingEnergyCard
0c:7de9 PsychicEnergyCard
0c:7df7 DoubleColorlessEnergyCard
0c:7e05 ProfessorOakCard
0c:7e13 ImposterProfessorOakCard
0c:7e21 BillCard
0c:7e2f MrFujiCard
0c:7e3d LassCard
0c:7e4b ImakuniCard
0c:7e59 PokemonTraderCard
0c:7e67 PokemonBreederCard
0c:7e75 ClefairyDollCard
0c:7e83 MysteriousFossilCard
0c:7e91 EnergyRetrievalCard
0c:7e9f SuperEnergyRetrievalCard
0c:7ead EnergySearchCard
0c:7ebb EnergyRemovalCard
0c:7ec9 SuperEnergyRemovalCard
0c:7ed7 SwitchCard
0c:7ee5 PokemonCenterCard
0c:7ef3 PokeBallCard
0c:7f01 ScoopUpCard
0c:7f0f ComputerSearchCard
0c:7f1d PokedexCard
0c:7f2b PlusPowerCard
0c:7f39 DefenderCard
0c:7f47 ItemFinderCard
0c:7f55 GustOfWindCard
0c:7f63 DevolutionSprayCard
0c:7f71 PotionCard
0c:7f7f SuperPotionCard
0c:7f8d FullHealCard
0c:7f9b ReviveCard
0c:7fa9 MaintenanceCard
0c:7fb7 PokemonFluteCard
0c:7fc5 GamblerCard
0c:7fd3 RecycleCard
'''.strip().split("\n")

idx = 0xc3-0xd3+0x10

for card in cards:
    idx += 1
    card = card.strip().split(" ")
    loc = card[0].split(":")
    if is_pkmn(int(loc[0], 16), int(loc[1], 16)):
        continue
    print("=== %s (%.2x) ===" % (card[1],idx if idx>=0xc3 else idx-0xbb))
    print()
    dump_all(int(loc[0], 16), int(loc[1], 16))
    print()