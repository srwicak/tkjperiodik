function password_check() {
  const strength = {
    0: "Sangat Lemah",
    1: "Lemah",
    2: "Cukup",
    3: "Baik",
    4: "Kuat"
  };

  const password = document.getElementById('password');
  const meterdiv = document.getElementById('meter-div');
  const meter = document.getElementById('password-strength-meter');
  const usp = document.getElementById('user_password_strength');
  const text = document.getElementById('password-strength-text');

  function updatePasswordStrength() {
    const val = password.value;
    const result = zxcvbn(val);

    // Update the password strength meter
    meter.value = result.score;
    usp.value = result.score;

    // Update the text indicator
    if (val !== "") {
      text.innerHTML = `Kekuatan: ${strength[result.score]}<br> Minimum: 8 Karakter dan Kekuatan Cukup`;
      meterdiv.classList.remove("hidden");
    } else {
      text.innerHTML = "";
      meterdiv.classList.add("hidden");
    }
  }

  // Memanggil fungsi updatePasswordStrength saat input password diubah
  password.addEventListener('input', updatePasswordStrength);

  // Panggil updatePasswordStrength saat halaman pertama kali dimuat
  updatePasswordStrength();
}


document.addEventListener('turbo:load', password_check);
document.addEventListener('turbo:render', password_check);
