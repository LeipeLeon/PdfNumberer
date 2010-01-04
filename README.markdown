# Syntax

    bin/numberer.command <config file>       Load alternative config file (Default ~/pdf_numberer)
    ENV=DEBUG bin/numberer.command           debugging mode
    bin/numberer.command -h                  this screen

In debugging mode worden op de resulterende PDF's een grid geplaatst ten behoeve van positionering.

# Config

Een voorbeel configuratie bestand: (geplaatst in `~/pdf_numberer`)

    --- 
    options: 
      default: 
        folder_in: ~/Desktop/BerieDataProjecten/2009-VDA-CVZ/test/in
        folder_out: ~/Desktop/BerieDataProjecten/2009-VDA-CVZ/test/out
        folder_processed: ~/Desktop/BerieDataProjecten/2009-VDA-CVZ/test/processed
        code_format: "{ordernumber}-{date}-{counter}-{filename}"
        rotation: -90
        x: 30
        y: 600
        on_pages: 
        - 1
        - 5
    counter: 
      default: 0
      4001000: 80

### Per optie:

<dt>`folder_in:`</dt>
  <dd>de watchfolder, bestanden die hierin worden geplaats worden door het script verwerkt.</dd>
<dt>`folder_out:`</dt>
  <dd>Hierin worden de aangepaste bestanden geplaatst. (deze _kan_ op een ander filesysteem worden geplaatst, maar dit wordt afgeraden i.v.m. performance)</dd>
<dt>`folder_processed:`</dt>
  <dd>In deze map komen de orginele bestanden terecht (**moet op hetzelfde filesystem als `folder_in` staan!**)</dd>
<dt>`code_format:`</dt>
  <dd>Format van code string, opties zijn `ordernumber`, `date`, `counter` en `filename`. Deze moeten dan door `{}` worden omsloten</dd>
<dt>`file_out_format:`</dt>
  <dd>Formattering van output filename (extensie __moet__ in string, opties zijn hetzelfde als `code_format:`)</dd>
<dt>`max_filename_size:`</dt>
  <dd>Maximale lengte van uitgaande bestandsnaam (laat applicatie niet chrashen maar geeft foutmelding in terminal)</dd>
<dt>`rotation:`</dt>
  <dd>Rotatie van de code (ClockWise)</dd>
<dt>`x:`, `y:`</dt>
  <dd>Links boven hoek van het code block</dd>
<dt>`on_pages:`</dt>
  <dd>Op welke pagina's moet de code staan.</dd>

### Differentiatie per order

We hebben globale opties die op ordernummer kunnen worden aangepast:

**Met uitzondering van _`folder_in`_, _`folder_out`_ en _`folder_processed`_**

    options: 
      default: 
        ....
        code_format: "{ordernumber}-{date}-{counter}-{filename}"
      4001001: 
        code_format: "{date}-{counter}-{filename}"

De counter wordt automatisch aangemaakt en bewaard voor een ordernummer:

    counter: 
      default: 0
      4001000: 80

De default is het start nummer van een nieuwe order. (teller wordt eerst verhoogd zodat als default op 0 staat de eerste pdf dan begint met 1)

Restricties:
============

- `folder_in` en `folder_processed` moeten op hetzelfde filesysteem staan.
- Test met extreem veel bestanden is nog niet uitgevoerd. (er is een automatische wachtijd van het aantal bestanden * 10 millisec)
- Aanpassingen in de config file alleen doen als het programma gestopt is, bestanden worden namelijk overschreven.
- De software draait op dit moment alleen op OSX 10.6 (Leopard)

Truuks
======

- Als de bestanden niet worden opgepikt (b.v. als de bestanden al geplaatst zijn en het script wordt daarna pas opgestart) kun je in de finder het mapje 'openen/sluiten' in de lijstweergave
- Door het bestand `bin/pdf_numberer.command` te openen met dubbelklik wordt automatisch een terminal scherm geopend met het programma