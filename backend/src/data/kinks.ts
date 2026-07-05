export interface KinkSeed {
  key: string;
  name: string;
  description: string;
  hasRoleVariant: boolean;
  /** Difficulty/hardness tier: 1 = vanilla, 2 = harder, 3 = the really intense stuff. */
  intensity: 1 | 2 | 3;
  /** Display label for the first selectable role (shown instead of generic "Adnám"). */
  roleA?: string;
  /** Display label for the second selectable role (shown instead of generic "Kapnám"). */
  roleB?: string;
}

/**
 * Canonical kink/preference catalog. `key` is a stable slug used for seeding
 * (safe to re-run) - never reuse a key for a different item once shipped,
 * since existing Response/Match rows reference the resulting Kink.id.
 *
 * `roleA` / `roleB` are the role-selection labels shown when `hasRoleVariant` is true.
 */
export const KINK_CATALOG: KinkSeed[] = [
  { key: "foot-licking", name: "Talpnyalás", description: "A partner talpának nyalása vagy csókolása okoz izgalmat.", hasRoleVariant: true, intensity: 1, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "high-heel-fetish", name: "Magassarkú-fetis", description: "A magassarkú cipő különösen vonzó.", hasRoleVariant: false, intensity: 1 },
  { key: "stocking-fetish", name: "Harisnyafetis", description: "Harisnya vagy combfix viselése/látványa izgató.", hasRoleVariant: false, intensity: 1 },
  { key: "sock-fetish", name: "Zoknifetis", description: "A zoknik erotikus vonzalmat keltenek.", hasRoleVariant: true, intensity: 1, roleA: "Rajtam", roleB: "Máson" },
  { key: "mask-fetish", name: "Maszkfetis", description: "Maszkok viselése erotikus élményt ad.", hasRoleVariant: true, intensity: 1, roleA: "Rajtam", roleB: "Máson" },
  { key: "latex-fetish", name: "Latexfetis", description: "A latex ruházat látványa vagy viselése izgató.", hasRoleVariant: false, intensity: 1 },
  { key: "glasses-fetish", name: "Szemüvegfetis", description: "A szemüveg különösen vonzó.", hasRoleVariant: false, intensity: 1 },
  { key: "spit-play", name: "Nyáljáték", description: "A nyállal kapcsolatos játékok okoznak izgalmat.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "leather-fetish", name: "Bőrruha-fetis", description: "A bőrből készült ruházat erotikus.", hasRoleVariant: false, intensity: 1 },
  { key: "collar", name: "Nyakörv", description: "Nyakörv viselése a szerepjáték része.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "ruined-orgasm", name: "Ruined orgasm", description: "Az orgazmust szándékosan megszakítják vagy csökkentik.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "tickling", name: "Csiklandozás", description: "A csiklandozás okoz izgalmat.", hasRoleVariant: true, intensity: 1, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "face-spitting", name: "Arcköpés", description: "A partner arcára köpés része a dinamikának.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "mouth-spitting", name: "Szájba köpés", description: "A partner szájába köpés.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "slapping", name: "Pofon", description: "Enyhe arcpofonok okoznak izgalmat.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "spanking", name: "Fenékcsapkodás", description: "Erősebb fenékütések iránti érdeklődés.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "ball-squeezing", name: "Hereszorítás (Ball squeezing)", description: "A herék kézzel vagy erre alkalmas eszközzel történő kontrollált szorítása része a játéknak.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "nipple-clamps", name: "Mellbimbócsipeszek", description: "Csipeszekkel fokozzák a mellbimbó érzékenységét.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "ball-busting", name: "Herék ütése (Ball busting)", description: "A herék kontrollált ütése, rúgása vagy csapkodása okoz izgalmat egyesek számára.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "nipple-play", name: "Mellbimbó-játék", description: "A mellbimbók ingerlése áll a középpontban.", hasRoleVariant: true, intensity: 1, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "clothed-facesitting", name: "Clothed facesitting", description: "Amikor valaki ruhában vagy alsóneműben ül a partner arcára.", hasRoleVariant: true, intensity: 1, roleA: "Ül", roleB: "Alatta" },
  { key: "wax-play", name: "Viaszjáték", description: "Meleg gyertyaviaszt cseppentenek a bőrre.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "ice-play", name: "Jégjáték", description: "Hideg tárgyakkal fokozzák az érzékelést.", hasRoleVariant: true, intensity: 1, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "blindfold", name: "Szemkötő", description: "A látás kizárása növeli az izgalmat.", hasRoleVariant: true, intensity: 1, roleA: "Köti", roleB: "Viseli" },
  { key: "handcuffs", name: "Bilincs használata", description: "A partner mozgását bilincs korlátozza.", hasRoleVariant: true, intensity: 1, roleA: "Megbilincsel", roleB: "Bilincses" },
  { key: "rope-bondage", name: "Kötéllel kötözés", description: "A test kötéllel történő megkötése része a játéknak.", hasRoleVariant: true, intensity: 2, roleA: "Köt", roleB: "Kötözött" },
  { key: "gag", name: "Szájpecek (Gag)", description: "A beszéd korlátozása fokozza az élményt.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "orgasm-control", name: "Orgazmuskontroll", description: "Az egyik fél irányítja, mikor vagy hogy a másik elélvezhet-e.", hasRoleVariant: true, intensity: 2, roleA: "Irányít", roleB: "Engedelmeskedik" },
  { key: "edging", name: "Edging", description: "Az orgazmus közelébe viszik a partnert, majd megállnak, ezt többször ismétlik.", hasRoleVariant: true, intensity: 1, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "clothed-femdom", name: "Clothed femdom", description: "Tágabb kategória, amelyben a domináns nő végig felöltözve marad; ennek egyik eleme lehet a ruhában történő facesitting.", hasRoleVariant: true, intensity: 2, roleA: "Domina", roleB: "Szubmisszív" },
  { key: "overstimulation", name: "Overstimulation", description: "Az orgazmus után is folytatódó ingerlés, amely a túlérzékenységgel jár.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "rough-glans-stimulation", name: "Rough glans stimulation", description: "A makk erőteljes ingerlése tenyérrel vagy egyéb módon.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "rough-clitoral-stimulation", name: "Rough clitoral stimulation", description: "A csikló intenzív vagy akár fájdalmas ingerlése.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "anal-sex", name: "Anális szex (Anal sex)", description: "Amikor a szexuális behatolás a végbélen keresztül történik.", hasRoleVariant: true, intensity: 2, roleA: "Aktív", roleB: "Passzív" },
  { key: "tease-and-denial", name: "Tease and denial", description: "Folyamatos ingerlés történik, de az orgazmust hosszabb ideig nem engedik.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "chastity", name: "Chastity", description: "Zárható eszközzel ideiglenesen megakadályozzák a szexuális kielégülést.", hasRoleVariant: true, intensity: 3, roleA: "Zárolja", roleB: "Viseli" },
  { key: "praise-kink", name: "Praise kink", description: "A dicséret és elismerés különösen izgató.", hasRoleVariant: true, intensity: 1, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "humiliation", name: "Megalázás (Humiliation)", description: "A megalázó helyzetek vagy szavak erotikusak.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "verbal-humiliation", name: "Verbális megalázás", description: "Kifejezetten sértő vagy lealacsonyító beszéd része a játéknak.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "degradation", name: "Degradation", description: "A partner alacsonyabb státuszúnak kezelése izgató.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "worship", name: "Worship", description: "A partner testének vagy egy részének imádata, tisztelete erotikus.", hasRoleVariant: true, intensity: 1, roleA: "Imád", roleB: "Imádják" },
  { key: "foot-worship", name: "Lábimádat (Foot worship)", description: "A lábak csókolása, nyalása vagy masszírozása áll a középpontban.", hasRoleVariant: true, intensity: 1, roleA: "Imád", roleB: "Imádják" },
  { key: "facesitting", name: "Arcra ülés (Facesitting)", description: "Az egyik partner a másik arcára ül orális szex közben.", hasRoleVariant: true, intensity: 2, roleA: "Ül", roleB: "Alatta" },
  { key: "queening", name: "Queening", description: "Facesitting domináns fókuszban: az ülő fél aktívan mozog, súlyt helyez a partnerre, irányít – a kontroll kerül előtérbe.", hasRoleVariant: true, intensity: 3, roleA: "Ül", roleB: "Alatta" },
  { key: "pet-play", name: "Pet play", description: "Az egyik fél háziállatként (pl. kutya, macska) viselkedik szerepjátékban.", hasRoleVariant: true, intensity: 3, roleA: "Gazda", roleB: "Kisállat" },
  { key: "furry-roleplay", name: "Furry roleplay", description: "Állatszerű karakterek vagy jelmezek szerepelnek az erotikus játékban.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "age-play", name: "Age play", description: "A résztvevők eltérő életkorú szerepeket játszanak el; ez kizárólag beleegyező felnőttek között történik.", hasRoleVariant: true, intensity: 1, roleA: "Gondozó", roleB: "Kicsi" },
  { key: "forced-orgasm", name: "Forced orgasm", description: "Az orgazmus ismételt kiváltása a beleegyezett játék részeként.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "mommy-dynamic", name: "Mommy dinamika", description: "Gondoskodó–irányító szerep.", hasRoleVariant: true, intensity: 2, roleA: "Mommy", roleB: "Kicsi" },
  { key: "daddy-dynamic", name: "Daddy dinamika", description: "Gondoskodó–irányító szerep.", hasRoleVariant: true, intensity: 2, roleA: "Daddy", roleB: "Kicsi" },
  { key: "cuckold-fantasy", name: "Cuckold fantázia", description: "Izgalmat okoz a gondolat vagy helyzet, hogy a partner mással létesít szexuális kapcsolatot.", hasRoleVariant: false, intensity: 3 },
  { key: "hotwife-fantasy", name: "Hotwife fantázia", description: "A pár egyik tagját izgatja, hogy a női partner más férfiakkal létesít kapcsolatot.", hasRoleVariant: false, intensity: 3 },
  { key: "exhibitionism", name: "Exhibitionizmus", description: "Az izgalom abból ered, hogy mások előtt mutatják meg magukat (csak beleegyező környezetben).", hasRoleVariant: false, intensity: 1 },
  { key: "roleplay", name: "Roleplay", description: "Kitalált szerepek (pl. tanár–diák, főnök–alkalmazott) eljátszása.", hasRoleVariant: false, intensity: 1 },
  { key: "primal-play", name: "Primal play", description: "Civilizált szerepek helyett ösztönös, ragadozó–préda jellegű játék, gyakran morgással, üldözéssel vagy birkózással.", hasRoleVariant: true, intensity: 2, roleA: "Vadász", roleB: "Préda" },
  { key: "prostate-play", name: "Prostate play", description: "A prosztata ingerlése áll a középpontban.", hasRoleVariant: true, intensity: 3, roleA: "Aktív", roleB: "Passzív" },
  { key: "sounding", name: "Sounding", description: "Speciális eszköz bevezetése a húgycsőbe erotikus célból.", hasRoleVariant: true, intensity: 3, roleA: "Aktív", roleB: "Passzív" },
  { key: "golden-shower", name: "Aranyzuhany (Golden shower)", description: "A vizelet egyik partnerről a másikra kerül a kölcsönösen elfogadott játék részeként.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "sweat-fetish", name: "Izzadságfetis", description: "Az izzadság szaga, érintése vagy látványa erotikus vonzalmat vált ki.", hasRoleVariant: false, intensity: 1 },
  { key: "chocolate-play", name: "Csokoládéjáték", description: "Csokoládé bevonása a játékba.", hasRoleVariant: false, intensity: 1 },
  { key: "whipped-cream-play", name: "Tejszínhab-játék", description: "Tejszínhab használata érzéki játékként.", hasRoleVariant: false, intensity: 1 },
  { key: "oil-massage", name: "Olajmasszázs", description: "Illó- vagy masszázsolaj használata erotikus célból.", hasRoleVariant: true, intensity: 1, roleA: "Masszőr", roleB: "Masszírozott" },
  { key: "mirror-play", name: "Tükör előtt", description: "A saját vagy partner látványa fokozza az élményt.", hasRoleVariant: false, intensity: 1 },
  { key: "public-fantasy", name: "Nyilvános hely fantázia", description: "Mások közelsége fokozza az izgalmat (csak jogszerű és beleegyező helyzetekben).", hasRoleVariant: false, intensity: 2 },
  { key: "remote-controlled-toys", name: "Távirányítású eszközök", description: "Partner által irányított eszközök használata.", hasRoleVariant: true, intensity: 1, roleA: "Irányít", roleB: "Visel" },
  { key: "cosplay", name: "Cosplay", description: "Ismert karakterek jelmezének erotikus használata.", hasRoleVariant: false, intensity: 1 },
  { key: "open-relationship", name: "Nyitott kapcsolat", description: "A kapcsolat enged más partnereket is.", hasRoleVariant: false, intensity: 2 },
  { key: "swinger-lifestyle", name: "Swinger életmód", description: "Párok közötti partnercsere közös beleegyezéssel.", hasRoleVariant: false, intensity: 2 },
  { key: "maid-roleplay", name: "Szobalány szerepjáték", description: "Kiszolgáló szerep eljátszása.", hasRoleVariant: true, intensity: 1, roleA: "Gazda", roleB: "Szobalány" },
  { key: "doctor-patient-roleplay", name: "Orvos–beteg szerepjáték", description: "Egészségügyi szerepek eljátszása.", hasRoleVariant: true, intensity: 1, roleA: "Orvos", roleB: "Beteg" },
  { key: "teacher-student-roleplay", name: "Tanár–diák szerepjáték", description: "Előre megbeszélt szerepek eljátszása.", hasRoleVariant: true, intensity: 1, roleA: "Tanár", roleB: "Diák" },
  { key: "smothering-fetish", name: "Smothering fetish", description: "Olyan kink, amelyben az egyik fél számára izgalmat jelent a légzés részleges korlátozásának érzete a partner testével.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "breast-squeezing-copy", name: "Breast squeezing", description: "A mellek erőteljes szorítása.", hasRoleVariant: true, intensity: 1, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "cum-eating", name: "Cum eating", description: "A saját ejakulátum lenyelése erotikus élményt jelent.", hasRoleVariant: false, intensity: 2 },
  { key: "cum-feeding", name: "Cum feeding", description: "Az egyik partner a másik partnerrel lenyeleti az ejakulátumot a közösen elfogadott játék részeként.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "snowballing", name: "Snowballing", description: "Az ejakulátum csókolózás közbeni átadása a partnerek között.", hasRoleVariant: false, intensity: 2 },
  { key: "breath-play", name: "Breath play", description: "A légzés kontrolljával vagy korlátozásának érzetével kapcsolatos, előre egyeztetett játék.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "cfnm", name: "CFNM (Clothed Female, Naked Male)", description: "A nő felöltözve marad, míg a férfi meztelen; a ruházati kontraszt áll a középpontban.", hasRoleVariant: false, intensity: 1 },
  { key: "cmnf", name: "CMNF (Clothed Male, Naked Female)", description: "A férfi felöltözve marad, míg a nő meztelen; a ruházati kontraszt okoz izgalmat.", hasRoleVariant: false, intensity: 1 },
  { key: "bdsm", name: "BDSM", description: "Átfogó érdeklődés a BDSM különböző formái iránt, nem egyetlen konkrét kinkre korlátozva.", hasRoleVariant: false, intensity: 2 },
  { key: "dom-sub-dynamic", name: "Dominancia–szubmisszió (D/s dinamika)", description: "Hosszabb távú alá- és fölérendeltségi szerepek, szabályokkal, jutalmazással vagy büntetéssel.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "joi", name: "JOI (Jerk Off Instruction)", description: "Az egyik partner utasításokat ad a másiknak az önkielégítéshez.", hasRoleVariant: true, intensity: 1, roleA: "Utasít", roleB: "Teljesíti" },
  { key: "tease-only", name: "Tease only / No-touch teasing", description: "Az egyik partner csak nézheti a másik önkielégítését vagy erotikus játékát, de nem érhet hozzá.", hasRoleVariant: true, intensity: 1, roleA: "Mutat", roleB: "Nézi" },
  { key: "head-scissors", name: "Head scissors (Head scissoring)", description: "A partner fejének a combok közötti kontrollált leszorítása a játék részeként.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "post-orgasm-torture", name: "Post-orgasm torture", description: "Az orgazmus után is folytatódó intenzív ingerlés, amely a túlérzékenységre épül.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "mutual-masturbation", name: "Mutual masturbation", description: "A partnerek egymás jelenlétében, kölcsönösen végeznek önkielégítést.", hasRoleVariant: false, intensity: 1 },
  { key: "paddle", name: "Paddle", description: "Lapos ütőeszközzel adott kontrollált ütések okoznak izgalmat.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "findom", name: "Findom (Financial domination)", description: "A domináns fél pénzügyi kontrollja vagy ajándékok, pénz átadása a beleegyezett dinamika részeként okoz izgalmat.", hasRoleVariant: true, intensity: 2, roleA: "Domina", roleB: "Fizető" },
  { key: "flogging", name: "Flogging", description: "Többszálú korbáccsal adott kontrollált ütések a játék részei.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "cnc", name: "CNC (Consensual Non-Consent)", description: "Előre részletesen egyeztetett szerepjáték, amely a beleegyezésen alapuló, nem beleegyezésnek tűnő helyzeteket jeleníti meg.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "voyeurism", name: "Voyeurizmus (Voyeurism)", description: "Mások intim vagy szexuális tevékenységének beleegyezéssel történő megfigyelése okoz izgalmat.", hasRoleVariant: false, intensity: 1 },
  { key: "dryhumping", name: "Dryhumping (Frottázs)", description: "A testek egymáshoz dörzsölése ruhában vagy részben felöltözve okoz izgalmat.", hasRoleVariant: false, intensity: 1 },

  // --- Femdom & szerepdinamikák ---
  { key: "femdom", name: "Femdom", description: "Általános női dominancia, ahol a nő átveszi az irányítást a szexuális dinamikában.", hasRoleVariant: true, intensity: 2, roleA: "Domina", roleB: "Szubmisszív" },
  { key: "gentle-femdom", name: "Gentle Femdom (GFD)", description: "Gyengéd, gondoskodó, szeretetteljes dominancia – az irányítás nem büntetésen, hanem törődésen alapul.", hasRoleVariant: true, intensity: 1, roleA: "Domina", roleB: "Szubmisszív" },
  { key: "service-submission", name: "Service submission", description: "Az egyik fél kiszolgálja a másikat: masszázs, italok elkészítése, cipőhúzás, testi gondoskodás.", hasRoleVariant: true, intensity: 1, roleA: "Kiszolgált", roleB: "Kiszolgáló" },
  { key: "domestic-servitude", name: "Domestic servitude", description: "A házimunka (takarítás, főzés, rendrakás) beleegyezett hatalmi dinamika részeként jelenik meg.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szolgál" },
  { key: "brat-dynamic", name: "Brat / Brat Tamer", description: "A makacs szubmisszív (Brat) szándékosan provokál; a domináns (Brat Tamer) reagál rá – versengő, játékos hatalmi dinamika.", hasRoleVariant: true, intensity: 2, roleA: "Brat Tamer", roleB: "Brat" },
  { key: "protocol", name: "Protokoll (D/s)", description: "Formalizált viselkedési szabályok, rituálék és udvariassági normák a domináns–szubmisszív kapcsolatban.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "obedience-training", name: "Engedelmességi tréning", description: "Rendszeres, strukturált engedelmességi gyakorlatok a szubmisszív számára.", hasRoleVariant: true, intensity: 2, roleA: "Edző", roleB: "Tanuló" },
  { key: "tpe", name: "TPE (Total Power Exchange)", description: "Teljes hatalomátadás: a domináns átveszi az irányítást az élet szinte minden területén, kölcsönös beleegyezéssel.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "mirror-domination", name: "Tükrös dominancia", description: "Tükör előtt zajló dominancia-játék, ahol a látvány – a szubmisszív saját tükörképe – a megalázás vagy kontroll eszköze.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "erotic-hypnosis", name: "Erotikus hipnózis", description: "Hipnózis vagy hipnózisszerű állapot alkalmazása az erotikus élmény fokozásához.", hasRoleVariant: true, intensity: 2, roleA: "Hipnotizőr", roleB: "Szubmisszív" },
  { key: "free-use-fantasy", name: "Free use fantázia", description: "Az egyik fél beleegyezetten bármikor rendelkezésre áll a másik számára, bármilyen szexuális célból.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },

  // --- Kötözés ---
  { key: "shibari", name: "Shibari", description: "A japán kötözés esztétikája: a kötelék vizuális szépsége, a rituálé és az érzelmi kapcsolat a középpont.", hasRoleVariant: true, intensity: 2, roleA: "Rigger", roleB: "Bunny" },

  // --- Impact play ---
  { key: "impact-play", name: "Impact play", description: "Általános érdeklődés az ütéssel járó játékok iránt (spanking, korbács, paddle, cane stb.).", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "riding-crop", name: "Lovaglóostor (Riding crop)", description: "Lovaglóostorral adott kontrollált ütések az erotikus dinamika részeként.", hasRoleVariant: true, intensity: 2, roleA: "Domináns", roleB: "Szubmisszív" },
  { key: "cane-play", name: "Cane play", description: "Vékony nádpálcával vagy bottal adott kontrollált ütések okoznak izgalmat.", hasRoleVariant: true, intensity: 3, roleA: "Domináns", roleB: "Szubmisszív" },

  // --- Érzékszervek ---
  { key: "sensory-play", name: "Sensory play", description: "Az érzékszervek célzott ingerlése (tapintás, hő, vibráció, textúrák) fokozza az élményt.", hasRoleVariant: true, intensity: 1, roleA: "Irányít", roleB: "Átéli" },
  { key: "sensory-deprivation", name: "Érzékszervi megfosztás (Sensory deprivation)", description: "A látás, hallás vagy tapintás részleges/teljes kizárása – az elvont érzékek helyett a maradók felerősödnek.", hasRoleVariant: true, intensity: 2, roleA: "Irányít", roleB: "Átéli" },

  // --- Imádat ---
  { key: "boot-worship", name: "Csizmaimádat (Boot worship)", description: "Csizmák és cipők csókolása, nyalása, tisztítása a beleegyezett imádó dinamika részeként.", hasRoleVariant: true, intensity: 1, roleA: "Imád", roleB: "Imádják" },

  // --- Helyszínek & fantáziák ---
  { key: "size-difference-fantasy", name: "Méretbeli különbség fantázia", description: "A partnerek testi méretbeli eltérése (magasság, testalkat) erotikus vonzalmat kelt.", hasRoleVariant: false, intensity: 1 },
  { key: "kitchen-play", name: "Konyhai játék", description: "Erotikus tevékenység vagy szex a konyhában – a hétköznapi helyszín adja az izgalmat.", hasRoleVariant: false, intensity: 1 },
  { key: "shower-play", name: "Zuhanyzós játék", description: "Erotikus tevékenység zuhanyzás közben vagy alatt.", hasRoleVariant: false, intensity: 1 },
  { key: "car-sex-fantasy", name: "Autós szex fantázia", description: "Autóban való szexuális tevékenység – a szűk tér és a félelem az elfogástól fokozza az izgalmat.", hasRoleVariant: false, intensity: 1 },
  { key: "hotel-sex-fantasy", name: "Hoteles szex fantázia", description: "Hotelszobában való szex izgalma: anonimitás, idegen környezet, a hétköznapitól való elszakadás.", hasRoleVariant: false, intensity: 1 },

  // --- Ruházat & fetisek ---
  { key: "uniform-fetish", name: "Egyenruha-fetis", description: "Egyenruhák (rendőr, katona, orvos, pilóta stb.) viselése erotikus izgalmat kelt.", hasRoleVariant: false, intensity: 1 },
  { key: "lingerie-fetish", name: "Fehérnemű-fetis (Lingerie)", description: "Fehérnemű, hálóing vagy egyéb intim ruhadarabok látványa különösen izgató.", hasRoleVariant: false, intensity: 1 },
];