
import { Resend } from 'resend';
import dotenv from 'dotenv';

dotenv.config();

const resend = process.env.RESEND_API
    ? new Resend(process.env.RESEND_API)
    : null;

const sendEmail = async ({ sendTo, subject, html }) => {
    if (!resend) {
        console.log('Email skipped: RESEND_API is not configured.');
        return null;
    }

    try {
        const { data, error } = await resend.emails.send({
            from: 'Leyo <noreply@amitprajapati.co.in>',
            to: sendTo,
            subject,
            html,
        });

        if (error) {
            console.error('Email sending failed:', error);
            return null;
        }

        return data;
    } catch (error) {
        console.error('Email error:', error);
        return null;
    }
};

export default sendEmail;
