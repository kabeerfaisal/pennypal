class CountryInfo {
  final String name;
  final String dial;
  final String flag;
  const CountryInfo(this.name, this.dial, this.flag);
}

const List<CountryInfo> kCountries = [
  CountryInfo('Pakistan', '+92', '🇵🇰'),
  CountryInfo('India', '+91', '🇮🇳'),
  CountryInfo('United States', '+1', '🇺🇸'),
  CountryInfo('United Kingdom', '+44', '🇬🇧'),
  CountryInfo('UAE', '+971', '🇦🇪'),
  CountryInfo('Saudi Arabia', '+966', '🇸🇦'),
  CountryInfo('Canada', '+1', '🇨🇦'),
  CountryInfo('Australia', '+61', '🇦🇺'),
  CountryInfo('Germany', '+49', '🇩🇪'),
  CountryInfo('France', '+33', '🇫🇷'),
  CountryInfo('Turkey', '+90', '🇹🇷'),
  CountryInfo('Bangladesh', '+880', '🇧🇩'),
  CountryInfo('China', '+86', '🇨🇳'),
  CountryInfo('Malaysia', '+60', '🇲🇾'),
  CountryInfo('Indonesia', '+62', '🇮🇩'),
  CountryInfo('Qatar', '+974', '🇶🇦'),
  CountryInfo('Kuwait', '+965', '🇰🇼'),
  CountryInfo('Oman', '+968', '🇴🇲'),
  CountryInfo('Egypt', '+20', '🇪🇬'),
  CountryInfo('Nigeria', '+234', '🇳🇬'),
];
