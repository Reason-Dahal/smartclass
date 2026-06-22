const generateTempPassword = () => {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#$%^&*';
    const all = uppercase + lowercase + numbers + special;
  
    const required = [
      uppercase[Math.floor(Math.random() * uppercase.length)],
      numbers[Math.floor(Math.random() * numbers.length)],
      special[Math.floor(Math.random() * special.length)],
    ];
  
    const rest = Array.from(
      { length: 5 },
      () => all[Math.floor(Math.random() * all.length)]
    );
  
    return [...required, ...rest]
      .sort(() => Math.random() - 0.5)
      .join('');
  };
  
  module.exports = generateTempPassword;