import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["identity", "rankSelect", "golonganField", "golonganDisplay", "golonganText"]
  static values = {
    examDate: String
  }

  connect() {
    // Load ranks data from script tag
    const ranksDataElement = document.getElementById('ranks-data')
    if (ranksDataElement) {
      try {
        this.ranksData = JSON.parse(ranksDataElement.textContent)
      } catch (e) {
        console.error('Failed to parse ranks data:', e)
        this.ranksData = { police: [], pns: [] }
      }
    } else {
      this.ranksData = { police: [], pns: [] }
    }
  }

  detectIdentityType(event) {
    const identity = event.target.value.trim()
    const length = identity.length

    if (!this.hasRankSelectTarget) return

    // Clear rank select first
    this.rankSelectTarget.innerHTML = '<option value="">Pilih Pangkat</option>'

    if (length === 8) {
      // Police (NRP)
      if (this.ranksData && this.ranksData.police) {
        this.populateRanks(this.ranksData.police)
      }
    } else if (length === 18) {
      // PNS (NIP)
      if (this.ranksData && this.ranksData.pns) {
        this.populateRanks(this.ranksData.pns)
      }
    }
  }

  populateRanks(ranks) {
    if (!this.hasRankSelectTarget) return
    if (!ranks || !Array.isArray(ranks)) return

    ranks.forEach(function(rank) {
      const option = document.createElement('option')
      option.value = rank
      option.textContent = rank
      this.rankSelectTarget.appendChild(option)
    }.bind(this))
  }

  autoCapitalizeName(event) {
    const input = event.target
    let value = input.value

    // Split by comma to preserve formatting after comma
    let parts = value.split(',')

    if (parts.length > 1) {
      // Uppercase before comma, preserve after
      parts[0] = parts[0].toUpperCase()
    } else {
      // Just uppercase everything
      parts[0] = parts[0].toUpperCase()
    }

    input.value = parts.join(',')
  }

  autoCapitalize(event) {
    const input = event.target
    input.value = input.value.toUpperCase()
  }

  calculateGolongan() {
    if (!this.examDateValue) return

    const dayElement = document.querySelector('[name="dob_day"]')
    const monthElement = document.querySelector('[name="dob_month"]')
    const yearElement = document.querySelector('[name="dob_year"]')

    if (!dayElement || !monthElement || !yearElement) return

    const day = dayElement.value
    const month = monthElement.value
    const year = yearElement.value

    if (!day || !month || !year) {
      this.hideGolongan()
      return
    }

    // Validate date components
    const dayNum = parseInt(day, 10)
    const monthNum = parseInt(month, 10)
    const yearNum = parseInt(year, 10)

    if (isNaN(dayNum) || isNaN(monthNum) || isNaN(yearNum)) {
      this.hideGolongan()
      return
    }

    if (dayNum < 1 || dayNum > 31 || monthNum < 1 || monthNum > 12 || yearNum < 1900) {
      this.hideGolongan()
      return
    }

    try {
      // Parse dates - Safari compatible
      const dob = new Date(yearNum, monthNum - 1, dayNum)
      const examDate = new Date(this.examDateValue)

      // Validate if date is valid (Safari compatible check)
      if (isNaN(dob.getTime()) || isNaN(examDate.getTime())) {
        this.hideGolongan()
        return
      }

      // Calculate age at exam date
      let age = examDate.getFullYear() - dob.getFullYear()
      const monthDiff = examDate.getMonth() - dob.getMonth()
      
      if (monthDiff < 0 || (monthDiff === 0 && examDate.getDate() < dob.getDate())) {
        age = age - 1
      }

      // Determine golongan
      let golongan
      let golonganText

      if (age < 31) {
        golongan = 1
        golonganText = "1 (18-30 tahun)"
      } else if (age < 41) {
        golongan = 2
        golonganText = "2 (31-40 tahun)"
      } else if (age < 51) {
        golongan = 3
        golonganText = "3 (41-50 tahun)"
      } else {
        golongan = 4
        golonganText = "4 (51+ tahun)"
      }

      // Update hidden field
      if (this.hasGolonganFieldTarget) {
        this.golonganFieldTarget.value = golongan
      }

      // Show golongan display
      this.showGolongan(golonganText)

    } catch (error) {
      console.error('Error calculating golongan:', error)
      this.hideGolongan()
    }
  }

  showGolongan(text) {
    if (this.hasGolonganDisplayTarget && this.hasGolonganTextTarget) {
      this.golonganTextTarget.textContent = text
      this.golonganDisplayTarget.classList.remove('hidden')
    }
  }

  hideGolongan() {
    if (this.hasGolonganDisplayTarget) {
      this.golonganDisplayTarget.classList.add('hidden')
    }
    if (this.hasGolonganFieldTarget) {
      this.golonganFieldTarget.value = ''
    }
  }
}
