const nodemailer = require("nodemailer");

const sendEmail = async (email, subject, text) => {
  try {
    // Cấu hình "người đưa thư"
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.USER_EMAIL, // Email Gmail của bạn
        pass: process.env.USER_PASS,  // 16 ký tự App Password từ Google Account
      },
    });

    // Cấu hình nội dung thư
    const mailOptions = {
      from: `🏸 Badminton App <${process.env.USER_EMAIL}>`,
      to: email,           // Email người nhận
      subject: subject,    // Tiêu đề email
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; border-radius: 5px;">
            <h2>🏸 Badminton Booking App</h2>
          </div>
          <div style="padding: 20px; background-color: #f9f9f9; border: 1px solid #ddd; border-radius: 5px; margin-top: 10px;">
            <p style="font-size: 16px; color: #333;">${text.replace(/\n/g, '<br>')}</p>
          </div>
          <div style="text-align: center; margin-top: 20px; font-size: 12px; color: #999;">
            <p>© 2026 Badminton Booking App. Tất cả quyền được bảo lưu.</p>
          </div>
        </div>
      `,
      text: text // Fallback text version
    };

    // Gửi email
    const info = await transporter.sendMail(mailOptions);
    console.log(`✅ Email đã được gửi thành công đến: ${email}`);
    return info;
  } catch (error) {
    console.error(`❌ Lỗi gửi email: ${error.message}`);
    throw error;
  }
};

module.exports = sendEmail;