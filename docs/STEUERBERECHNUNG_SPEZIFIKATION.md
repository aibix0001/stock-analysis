# 💰 Steuerberechnung Spezifikation - Deutsches Steuerrecht 2025

## 🎯 Grundsätze der Steuerberechnung

### ✅ Anwendbares Steuerrecht
- **Deutsches Steuerrecht** Stand 2025
- **Kapitalertragsteuer (KESt)**: 25% Flat Tax auf Kapitalgewinne
- **Solidaritätszuschlag (SolZ)**: 5,5% auf die Kapitalertragsteuer
- **Kirchensteuer (KiSt)**: 8% (evangelisch) oder 9% (katholisch) auf KESt (optional)

### 🚫 KEINE Steueroptimierungen
- **Keine Abschreibungen** oder steuerliche Verlustverrechnung
- **Keine Loss-Harvesting-Strategien**
- **Keine komplexen Optimierungsverfahren**
- **Einfache Standard-Berechnung** ohne steuerliche Tricks

## 📊 Berechnungsformeln

### Standard-Steuerberechnung für Kapitalgewinne
```
Kapitalgewinn = Verkaufspreis - Kaufpreis - Transaktionskosten

Kapitalertragsteuer (KESt) = Kapitalgewinn × 25%

Solidaritätszuschlag (SolZ) = KESt × 5,5%
                            = Kapitalgewinn × 1,375%

Kirchensteuer (KiSt) = KESt × 8% (evangelisch) oder KESt × 9% (katholisch)
                     = Kapitalgewinn × 2% oder Kapitalgewinn × 2,25%

Gesamtsteuer = KESt + SolZ + KiSt (optional)
```

### Effektive Steuersätze
```
Ohne Kirchensteuer:     25% + 1,375% = 26,375%
Mit Kirchensteuer 8%:   25% + 1,375% + 2% = 28,375%
Mit Kirchensteuer 9%:   25% + 1,375% + 2,25% = 28,625%
```

### Dividendenbesteuerung
```
Brutto-Dividende = Ausgeschütteter Betrag vor Steuern

Kapitalertragsteuer = Brutto-Dividende × 25%
Solidaritätszuschlag = Kapitalertragsteuer × 5,5%
Kirchensteuer = Kapitalertragsteuer × 8%/9% (optional)

Netto-Dividende = Brutto-Dividende - Gesamtsteuer

Quellensteuer-Anrechnung:
- Ausländische Quellensteuer wird NICHT automatisch verrechnet
- Einfache Berechnung ohne Doppelbesteuerungsabkommen-Optimierung
```

## 🗄️ Datenbank-Schema für Steuerberechnung

### tax_calculations Tabelle
```sql
CREATE TABLE tax_calculations (
    id INTEGER PRIMARY KEY,
    trade_id INTEGER NOT NULL,
    capital_gain DECIMAL(15,2) NOT NULL,
    
    -- Standard-Steuersätze (2025)
    kapitalertragsteuer_rate DECIMAL(5,4) DEFAULT 0.25,    -- 25%
    solidaritaetszuschlag_rate DECIMAL(5,4) DEFAULT 0.055, -- 5,5%
    kirchensteuer_rate DECIMAL(5,4) DEFAULT NULL,          -- 8% oder 9%
    
    -- Berechnete Steuerbeträge
    kapitalertragsteuer DECIMAL(15,2) NOT NULL,
    solidaritaetszuschlag DECIMAL(15,2) NOT NULL,
    kirchensteuer DECIMAL(15,2) DEFAULT 0,
    total_tax DECIMAL(15,2) NOT NULL,
    
    -- Metadaten
    calculation_date DATETIME NOT NULL,
    tax_year INTEGER NOT NULL,
    
    FOREIGN KEY (trade_id) REFERENCES trades(id)
);
```

### tax_simple_tracking Tabelle
```sql
CREATE TABLE tax_simple_tracking (
    id INTEGER PRIMARY KEY,
    position_id INTEGER NOT NULL,
    
    -- Einfache Steuer-Konfiguration
    kirchensteuer_enabled BOOLEAN DEFAULT FALSE,
    kirchensteuer_type TEXT CHECK(kirchensteuer_type IN ('evangelisch', 'katholisch')),
    
    -- Kumulative Steuern pro Position
    total_capital_gains DECIMAL(15,2) DEFAULT 0,
    total_taxes_paid DECIMAL(15,2) DEFAULT 0,
    
    -- KEINE Optimierungsfelder
    -- KEINE Verlustverrechnungen
    -- KEINE steuerlichen Strategien
    
    last_updated DATETIME NOT NULL,
    
    FOREIGN KEY (position_id) REFERENCES positions(id)
);
```

## 🧮 Implementation im performance-engine Modul

### TaxCalculator Klasse
```python
class SimpleTaxCalculator:
    """
    Einfache Steuerberechnung nach deutschem Steuerrecht 2025
    OHNE Optimierungen oder komplexe Strategien
    """
    
    # Standard-Steuersätze (fest codiert)
    KAPITALERTRAGSTEUER_RATE = 0.25      # 25%
    SOLIDARITAETSZUSCHLAG_RATE = 0.055   # 5,5%
    KIRCHENSTEUER_EVANGELISCH = 0.08     # 8%
    KIRCHENSTEUER_KATHOLISCH = 0.09      # 9%
    
    def calculate_capital_gains_tax(self, capital_gain: float, 
                                  kirchensteuer_enabled: bool = False,
                                  kirchensteuer_type: str = None) -> dict:
        """
        Berechnet Steuern auf Kapitalgewinne nach Standard-Verfahren
        
        Returns:
        {
            'kapitalertragsteuer': float,
            'solidaritaetszuschlag': float, 
            'kirchensteuer': float,
            'total_tax': float,
            'effective_rate': float,
            'net_gain': float
        }
        """
        if capital_gain <= 0:
            return self._zero_tax_result()
            
        # Standard-Berechnung ohne Optimierungen
        kest = capital_gain * self.KAPITALERTRAGSTEUER_RATE
        solz = kest * self.SOLIDARITAETSZUSCHLAG_RATE
        
        kirchensteuer = 0
        if kirchensteuer_enabled and kirchensteuer_type:
            if kirchensteuer_type == 'evangelisch':
                kirchensteuer = kest * self.KIRCHENSTEUER_EVANGELISCH
            elif kirchensteuer_type == 'katholisch':
                kirchensteuer = kest * self.KIRCHENSTEUER_KATHOLISCH
                
        total_tax = kest + solz + kirchensteuer
        effective_rate = total_tax / capital_gain
        net_gain = capital_gain - total_tax
        
        return {
            'kapitalertragsteuer': round(kest, 2),
            'solidaritaetszuschlag': round(solz, 2),
            'kirchensteuer': round(kirchensteuer, 2),
            'total_tax': round(total_tax, 2),
            'effective_rate': round(effective_rate, 4),
            'net_gain': round(net_gain, 2)
        }
```

## 🎯 Performance-Engine Integration

### Netto-Performance-Berechnung
```python
def calculate_net_performance(position):
    """
    Berechnet Netto-Performance inklusive Standard-Steuern
    """
    gross_gain = position.current_value - position.purchase_value
    transaction_costs = position.buy_fees + position.sell_fees
    
    # Nur bei Gewinnen Steuern berechnen
    if gross_gain > 0:
        tax_result = SimpleTaxCalculator.calculate_capital_gains_tax(
            capital_gain=gross_gain,
            kirchensteuer_enabled=position.kirchensteuer_enabled,
            kirchensteuer_type=position.kirchensteuer_type
        )
        total_taxes = tax_result['total_tax']
    else:
        total_taxes = 0  # Keine Verlustverrechnung
    
    net_performance = gross_gain - transaction_costs - total_taxes
    
    return {
        'gross_gain': gross_gain,
        'transaction_costs': transaction_costs,
        'taxes': total_taxes,
        'net_performance': net_performance,
        'net_return_percentage': net_performance / position.purchase_value
    }
```

## 📋 Konfiguration

### User-Konfiguration
```yaml
# depot_config.yaml
tax_settings:
  kirchensteuer:
    enabled: false
    type: null  # 'evangelisch' oder 'katholisch'
  
  # Feste Steuersätze (nicht änderbar)
  kapitalertragsteuer: 0.25
  solidaritaetszuschlag: 0.055
  
  # Keine Optimierungsoptionen verfügbar
  loss_harvesting: disabled
  tax_optimization: disabled
  carry_forward_losses: disabled
```

Diese **vereinfachte Steuerberechnung** gewährleistet:
- ✅ **Rechtskonforme Berechnung** nach deutschem Steuerrecht 2025
- ✅ **Einfache Implementierung** ohne komplexe Optimierungslogik
- ✅ **Transparente Berechnung** ohne versteckte steuerliche Tricks
- ✅ **Standard-konforme Ergebnisse** für private Kapitalanleger